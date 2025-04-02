import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class AlunoNotasScreen extends StatelessWidget {
  final String alunoId;
  final String alunoNome;
  final String? turma;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AlunoNotasScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.turma,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Boletim Escolar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        alunoNome[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      alunoNome,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Turma: ${turma ?? "Não definida"}',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('notas').doc(alunoId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();

                return Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Get the processed data
                      final notas =
                          snapshot.data?.data() as Map<String, dynamic>? ?? {};
                      final teachers =
                          await _firestore
                              .collection('users')
                              .where('role', isEqualTo: 'teacher')
                              .get();

                      final professoresComNotas = await _processTeachersData(
                        teachers.docs,
                        notas,
                      );

                      if (!context.mounted) return;

                      // Pass the data to PDF generation
                      _generateAndDownloadPDF(
                        context,
                        professoresComNotas.where((p) => p.isNotEmpty).toList(),
                      );
                    },
                    icon: Icon(Icons.download),
                    label: Text('Baixar Boletim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('notas').doc(alunoId).snapshots(),
              builder: (context, notasSnapshot) {
                if (notasSnapshot.hasError) {
                  return _buildErrorWidget('Erro ao carregar notas');
                }

                if (notasSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingWidget();
                }

                final notas =
                    notasSnapshot.data?.data() as Map<String, dynamic>? ?? {};

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('users')
                          .where('role', isEqualTo: 'teacher')
                          .snapshots(),
                  builder: (context, teachersSnapshot) {
                    if (teachersSnapshot.hasError) {
                      return _buildErrorWidget('Erro ao carregar professores');
                    }

                    if (teachersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingWidget();
                    }

                    final teachers = teachersSnapshot.data?.docs ?? [];

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _processTeachersData(teachers, notas),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingWidget();
                        }

                        if (snapshot.hasError) {
                          return _buildErrorWidget('Erro ao processar dados');
                        }

                        final professoresComNotas =
                            snapshot.data
                                ?.where((professor) => professor.isNotEmpty)
                                .toList() ??
                            [];

                        if (professoresComNotas.isEmpty) {
                          return _buildEmptyStateWidget();
                        }

                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildOverallStats(professoresComNotas),
                              SizedBox(height: 24),
                              _buildTeachersList(context, professoresComNotas),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13 and above
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();

        return photos.isGranted && videos.isGranted && audio.isGranted;
      } else if (sdkInt >= 30) {
        // Android 11 and 12
        final storage = await Permission.storage.request();
        final manageExternal = await Permission.manageExternalStorage.request();

        return storage.isGranted || manageExternal.isGranted;
      } else {
        // Android 10 and below
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }
    return true;
  }

  Future<String> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt.toString();
    }
    return '0';
  }

  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      if (int.parse(await _getAndroidVersion()) >= 33) {
        // Para Android 13 e superior, use getExternalStorageDirectory
        return await getExternalStorageDirectory();
      } else {
        // Para versões anteriores, use o diretório de downloads
        return Directory('/storage/emulated/0/Download');
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _generateAndDownloadPDF(
    BuildContext context,
    List<Map<String, dynamic>> professoresComNotas,
  ) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissão necessária para salvar o arquivo'),
            action: SnackBarAction(
              label: 'CONFIGURAÇÕES',
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        );
        return;
      }

      final directory = await _getDownloadDirectory();
      if (directory == null) {
        throw 'Não foi possível acessar o diretório de download';
      }

      // Create download directory
      Directory? downloadDirectory;
      if (Platform.isAndroid) {
        downloadDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadDirectory.exists()) {
          downloadDirectory = await getExternalStorageDirectory();
        }
      } else {
        downloadDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadDirectory == null) {
        throw 'Não foi possível acessar o diretório de download';
      }

      final pdf = pw.Document();

      // Load and convert the image
      final ByteData imageData = await rootBundle.load(
        'assets/images/logo.png',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();
      final image = pw.MemoryImage(imageBytes);

      // Criar o PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => [
                // Cabeçalho
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Boletim Escolar',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text('Aluno: $alunoNome'),
                          pw.Text('Turma: ${turma ?? "Não definida"}'),
                          pw.Text(
                            'Data: ${DateTime.now().toString().split(' ')[0]}',
                          ),
                        ],
                      ),
                      pw.Container(
                        width: 80,
                        height: 80,
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                // Tabela de Notas
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Cabeçalho da tabela
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Matéria',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '1º Ciclo',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '2º Ciclo',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '3º Ciclo',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Média',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Linhas de notas por matéria
                    ...processarNotasPorMateria(
                      professoresComNotas,
                    ).entries.map((entry) {
                      final materia = entry.key;
                      final notas = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(materia),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(notas['ciclo1']?.toString() ?? '-'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(notas['ciclo2']?.toString() ?? '-'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(notas['ciclo3']?.toString() ?? '-'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              calcularMedia(notas).toStringAsFixed(1),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Média Geral: ${calcularMediaGeral(processarNotasPorMateria(professoresComNotas)).toStringAsFixed(1)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
        ),
      );

      // Salvar o PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File(
        '${output.path}/boletim_${alunoNome.toLowerCase().replaceAll(' ', '_')}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Abrir o PDF
      await OpenFile.open(file.path);

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Boletim salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar boletim: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _processTeachersData(
    List<QueryDocumentSnapshot> teachers,
    Map<String, dynamic> notas,
  ) async {
    return await Future.wait(
      teachers.map((teacher) async {
        // Get user data from users collection
        final userDoc =
            await _firestore.collection('users').doc(teacher.id).get();
        if (!userDoc.exists) return {};

        final userData = userDoc.data() as Map<String, dynamic>;
        final String professorNome = userData['name'] ?? 'Professor sem nome';

        // Get teacher's subjects from teachers collection
        final teacherDoc =
            await _firestore.collection('teachers').doc(teacher.id).get();
        if (!teacherDoc.exists) return {};

        final teacherInfo = teacherDoc.data() as Map<String, dynamic>;
        final materias = List<String>.from(teacherInfo['materias'] ?? []);

        // Process grades for each cycle
        List<MapEntry<String, dynamic>> notasProfessor = [];
        for (var ciclo in ['ciclo1', 'ciclo2', 'ciclo3']) {
          final cicloData = notas[ciclo] as Map<String, dynamic>? ?? {};

          cicloData.forEach((materia, nota) {
            if (materias.contains(materia)) {
              notasProfessor.add(MapEntry('${ciclo}_$materia', nota));
            }
          });
        }

        if (notasProfessor.isNotEmpty) {
          print(
            'Professor: $professorNome, Notas: $notasProfessor',
          ); // Debug print

          return {
            'nome': professorNome,
            'id': teacher.id,
            'materias': materias,
            'notas': notasProfessor,
          };
        }
        return {};
      }),
    );
  }

  Widget _buildOverallStats(List<Map<String, dynamic>> professoresComNotas) {
    double mediaGeral = 0.0;
    int totalNotas = 0;

    for (var professor in professoresComNotas) {
      var notas = professor['notas'] as List;
      for (var nota in notas) {
        mediaGeral += double.parse(nota.value.toString());
        totalNotas++;
      }
    }

    mediaGeral = totalNotas > 0 ? mediaGeral / totalNotas : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Desempenho Geral',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Média Geral',
                  mediaGeral.toStringAsFixed(1),
                  Icons.grade,
                  _getStatusColor(mediaGeral),
                ),
                _buildStatItem(
                  'Total de Notas',
                  totalNotas.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTeachersList(
    BuildContext context,
    List<Map<String, dynamic>> professoresComNotas,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professores',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...professoresComNotas.map((professor) {
          final String professorNome =
              (professor['nome'] as String?) ?? 'Professor sem nome';
          final List<MapEntry<String, dynamic>> notas =
              List<MapEntry<String, dynamic>>.from(professor['notas']);

          // Calculate average grade for this teacher
          double media = 0;
          for (var nota in notas) {
            media += double.parse(nota.value.toString());
          }
          media = media / notas.length;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProfessorNotasScreen(
                          professorNome: professorNome,
                          alunoNome: alunoNome,
                          notas: notas,
                        ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      radius: 24,
                      child: Text(
                        professorNome.isNotEmpty
                            ? professorNome[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            professorNome,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${notas.length} matérias avaliadas',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(media),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        media.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'Nenhuma nota registrada',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(double value) {
    if (value >= 7) return Colors.green;
    if (value >= 5) return Colors.orange;
    return Colors.red;
  }

  Map<String, Map<String, double>> processarNotasPorMateria(
    List<Map<String, dynamic>> professoresComNotas,
  ) {
    final notasPorMateria = <String, Map<String, double>>{};

    for (var professor in professoresComNotas) {
      final notas = List<MapEntry<String, dynamic>>.from(professor['notas']);
      for (var nota in notas) {
        final partes = nota.key.split('_');
        final ciclo = partes[0];
        final materia = partes[1];

        notasPorMateria.putIfAbsent(materia, () => {});
        notasPorMateria[materia]![ciclo] = double.parse(nota.value.toString());
      }
    }

    return notasPorMateria;
  }

  double calcularMedia(Map<String, double> notas) {
    if (notas.isEmpty) return 0.0;
    return notas.values.reduce((a, b) => a + b) / notas.length;
  }

  double calcularMediaGeral(Map<String, Map<String, double>> notasPorMateria) {
    if (notasPorMateria.isEmpty) return 0.0;

    double somaMedias = 0.0;
    for (var notas in notasPorMateria.values) {
      somaMedias += calcularMedia(notas);
    }
    return somaMedias / notasPorMateria.length;
  }
}

class ProfessorNotasScreen extends StatefulWidget {
  final String professorNome;
  final String alunoNome;
  final List<MapEntry<String, dynamic>> notas;

  const ProfessorNotasScreen({
    super.key,
    required this.professorNome,
    required this.alunoNome,
    required this.notas,
  });

  @override
  State<ProfessorNotasScreen> createState() => _ProfessorNotasScreenState();
}

class _ProfessorNotasScreenState extends State<ProfessorNotasScreen> {
  int _selectedCiclo = 1;

  Color _getNotaColor(dynamic nota) {
    double value = double.parse(nota.toString());
    if (value >= 7) return Colors.green;
    if (value >= 5) return Colors.orange;
    return Colors.red;
  }

  Map<int, List<MapEntry<String, dynamic>>> _getNotasPorCiclo() {
    final notasPorCiclo = <int, List<MapEntry<String, dynamic>>>{};

    for (var ciclo in [1, 2, 3]) {
      notasPorCiclo[ciclo] =
          widget.notas
              .where((nota) => nota.key.contains('ciclo$ciclo'))
              .map(
                (nota) => MapEntry(
                  nota.key.replaceAll('ciclo${ciclo}_', ''),
                  nota.value,
                ),
              )
              .toList();
    }

    return notasPorCiclo;
  }

  Widget _buildGradeChart(List<MapEntry<String, dynamic>> notas) {
    if (notas.isEmpty) return Container();

    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          minY: 0,
          groupsSpace: 12,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.grey.shade800,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  notas[group.x.toInt()].value.toString(),
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= notas.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      notas[value.toInt()].key,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  );
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[300], strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(notas.length, (index) {
            final nota = double.parse(notas[index].value.toString());
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: nota,
                  color: _getNotaColor(nota),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notasPorCiclo = _getNotasPorCiclo();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Boletim por Professor',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Professor: ${widget.professorNome}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      'Aluno: ${widget.alunoNome}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          [1, 2, 3].map((ciclo) {
                            final isSelected = _selectedCiclo == ciclo;
                            return InkWell(
                              onTap:
                                  () => setState(() => _selectedCiclo = ciclo),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.primaryBlue
                                          : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Text(
                                  '${ciclo}º Ciclo',
                                  style: GoogleFonts.poppins(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 24),
                    _buildGradeChart(notasPorCiclo[_selectedCiclo] ?? []),
                  ],
                ),
              ),
            ),
            if (notasPorCiclo[_selectedCiclo]?.isNotEmpty ?? false) ...[
              SizedBox(height: 24),
              Text(
                'Detalhamento das Notas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ...notasPorCiclo[_selectedCiclo]!.map((nota) {
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getNotaColor(nota.value).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              nota.key.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getNotaColor(nota.value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nota.key,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      double.parse(nota.value.toString()) / 10,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getNotaColor(nota.value),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getNotaColor(nota.value),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            nota.value.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
