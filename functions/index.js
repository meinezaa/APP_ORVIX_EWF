const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const users = db.collection("users");

function staffInvitations(snapshot) {
  return snapshot.docs.filter((doc) => {
    const data = doc.data();
    return String(data.role || "").trim().toLowerCase() === "staff" &&
      data.account_created !== true &&
      data.pending_registration !== false;
  });
}

function isActive(data) {
  const status = String(data.status || "active").trim().toLowerCase();
  return data.isActive !== false &&
    data.aktif !== false &&
    status !== "inactive" &&
    status !== "nonaktif";
}

exports.registerStaff = onCall(async (request) => {
  const email = String(request.data?.email || "").trim().toLowerCase();
  const password = request.data?.password;
  const name = String(request.data?.nama || "").trim();
  const phone = String(request.data?.phone || "").trim();

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) ||
      typeof password !== "string" ||
      password.length < 8 ||
      !name ||
      name.length > 120 ||
      phone.length > 40) {
    throw new HttpsError("invalid-argument", "Data pendaftaran tidak valid.");
  }

  const initialSnapshot = await users.where("email", "==", email).limit(20).get();
  const initialInvitations = staffInvitations(initialSnapshot);
  if (initialInvitations.length === 0) {
    const accountExists = initialSnapshot.docs.some((doc) => {
      const data = doc.data();
      return String(data.role || "").trim().toLowerCase() === "staff" &&
        data.account_created === true;
    });
    if (accountExists) {
      throw new HttpsError(
          "already-exists",
          "Email ini sudah memiliki akun. Silakan masuk.",
      );
    }
    throw new HttpsError(
        "not-found",
        "Email ini belum didaftarkan oleh admin.",
    );
  }
  if (initialInvitations.length !== 1) {
    throw new HttpsError(
        "failed-precondition",
        "Undangan email tercatat lebih dari satu kali. Minta admin memeriksa data staff.",
    );
  }
  if (!isActive(initialInvitations[0].data())) {
    throw new HttpsError(
        "permission-denied",
        "Akun staff ini nonaktif. Hubungi admin.",
    );
  }

  let createdUser;
  try {
    try {
      createdUser = await auth.createUser({
        email,
        password,
        displayName: name,
      });
    } catch (error) {
      if (error.code === "auth/email-already-exists") {
        throw new HttpsError(
            "already-exists",
            "Email ini sudah memiliki akun Firebase. Silakan masuk atau gunakan Lupa Password.",
        );
      }
      throw error;
    }

    const profileReference = users.doc(createdUser.uid);
    await db.runTransaction(async (transaction) => {
      const currentSnapshot = await transaction.get(
          users.where("email", "==", email).limit(20),
      );
      const invitations = staffInvitations(currentSnapshot);
      if (invitations.length !== 1) {
        throw new HttpsError(
            "failed-precondition",
            "Undangan staff sudah berubah atau sudah digunakan. Minta admin memeriksa kembali.",
        );
      }

      const invitation = invitations[0];
      const invitationData = invitation.data();
      if (!isActive(invitationData)) {
        throw new HttpsError(
            "permission-denied",
            "Akun staff ini nonaktif. Hubungi admin.",
        );
      }
      const existingProfile = await transaction.get(profileReference);
      if (existingProfile.exists) {
        throw new HttpsError(
            "already-exists",
            "Profil akun sudah tersedia. Silakan masuk atau hubungi admin.",
        );
      }

      transaction.set(profileReference, {
        ...invitationData,
        user_id: createdUser.uid,
        nama: name,
        email,
        phone,
        role: "staff",
        status: "active",
        isActive: true,
        aktif: true,
        account_created: true,
        pending_registration: false,
        registeredAt: FieldValue.serverTimestamp(),
      });
      transaction.delete(invitation.ref);
    });
  } catch (error) {
    if (createdUser) {
      try {
        await auth.deleteUser(createdUser.uid);
      } catch (cleanupError) {
        console.error(
            "Failed to clean up Firebase Auth user after staff registration failed.",
            cleanupError,
        );
      }
    }
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("Staff registration failed.", error);
    throw new HttpsError(
        "internal",
        "Pendaftaran gagal disimpan. Silakan coba lagi.",
    );
  }

  return {success: true};
});
