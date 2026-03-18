const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.updateDoctorRating = functions.firestore
  .document("doctor_reviews/{reviewId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const doctorId = data.doctorId;
    const rating = data.rating;

    if (!doctorId || rating == null) return;

    const db = admin.firestore();

    const snapshot = await db
      .collection("doctor_reviews")
      .where("doctorId", "==", doctorId)
      .get();

    let total = 0;

    snapshot.forEach((doc) => {
      total += doc.data().rating || 0;
    });

    const count = snapshot.size;
    const avg = count > 0 ? total / count : 0;

    await db.collection("doctors").doc(doctorId).update({
      rating: avg,
      reviews: count,
      ratingTotal: total,
    });
  });