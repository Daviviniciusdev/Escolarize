const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = functions.firestore
  .document("announcements/{announcementId}")
  .onCreate(async (snap, context) => {
    const announcement = snap.data();
    const { title, message, targetRoles } = announcement;

    try {
      let usersQuery = admin.firestore().collection("users");
      
      if (!targetRoles.includes("all")) {
        usersQuery = usersQuery.where("role", "in", targetRoles);
      }

      const users = await usersQuery.get();
      const tokens = [];

      users.forEach((user) => {
        const userData = user.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No tokens found");
        return;
      }

      const notificationMessage = {
        notification: {
          title,
          body: message,
        },
        android: {
          notification: {
            icon: "@mipmap/ic_launcher",
            color: "#2196F3",
            priority: "high",
            channelId: "school_notifications",
          },
        },
        tokens,
      };

      const response = await admin.messaging().sendMulticast(notificationMessage);
      console.log(`Sent notifications: ${response.successCount}/${tokens.length}`);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });