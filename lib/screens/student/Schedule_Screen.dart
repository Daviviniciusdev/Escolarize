import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ScheduleScreen extends StatelessWidget {
  final String turma;

  const ScheduleScreen({super.key, required this.turma});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Horários - Turma $turma',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
            height: 2,
          ),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.primaryBlue,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wb_sunny),
                        SizedBox(width: 8),
                        Text('Manhã'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.nights_stay),
                        SizedBox(width: 8),
                        Text('Tarde'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildScheduleTable(isMorning: true),
                  _buildScheduleTable(isMorning: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTable({required bool isMorning}) {
    final horarios =
        isMorning
            ? [
              '07:00 - 07:50',
              '07:50 - 08:40',
              '08:40 - 09:20',
              'INTERVALO (09:20 - 09:40)',
              '09:40 - 10:30',
              '10:30 - 11:30',
            ]
            : [
              '13:00 - 13:50',
              '13:50 - 14:50',
              'INTERVALO (14:50 - 15:10)',
              '15:10 - 16:00',
              '16:00 - 17:00',
            ];

    return AnimationLimiter(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shadowColor: AppColors.primaryBlue.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.3),
                2: FlexColumnWidth(1.3),
                3: FlexColumnWidth(1.3),
                4: FlexColumnWidth(1.3),
                5: FlexColumnWidth(1.3),
              },
              children: [
                _buildHeaderRow(),
                ...List.generate(
                  horarios.length,
                  (index) => _buildTimeRow(horarios[index], index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
        ),
      ),
      children: [
        _buildHeaderCell('Horário'),
        _buildHeaderCell('Seg'),
        _buildHeaderCell('Ter'),
        _buildHeaderCell('Qua'),
        _buildHeaderCell('Qui'),
        _buildHeaderCell('Sex'),
      ],
    );
  }

  TableRow _buildTimeRow(String horario, int index) {
    bool isBreak = _isBreakTime(horario);
    return TableRow(
      decoration: BoxDecoration(
        color:
            isBreak
                ? Colors.amber.withOpacity(0.1)
                : index.isEven
                ? Colors.grey.shade50
                : Colors.white,
      ),
      children: _buildRowCells(horario),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isBreak = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: isHeader || isBreak ? FontWeight.w600 : FontWeight.normal,
          color:
              isBreak
                  ? Colors.amber[800]
                  : isHeader
                  ? AppColors.primaryBlue
                  : Colors.black87,
        ),
      ),
    );
  }

  bool _isBreakTime(String horario) {
    return horario.contains('INTERVALO');
  }

  List<Widget> _buildRowCells(String horario) {
    bool isBreak = _isBreakTime(horario);

    if (isBreak) {
      return [
        _buildCell(horario, isHeader: true, isBreak: true),
        ...List.generate(5, (_) => _buildBreakCell()),
      ];
    }

    return [
      _buildCell(horario, isHeader: true),
      ...List.generate(5, (_) => _buildEmptyCell()),
    ];
  }

  Widget _buildBreakCell() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.coffee, size: 14, color: Colors.amber[800]),
          SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Intervalo',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.amber[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
      ),
    );
  }
}
