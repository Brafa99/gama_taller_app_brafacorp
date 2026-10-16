const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccountNew = require('./serviceAccountKeyNew.json');

const appNew = initializeApp({ credential: cert(serviceAccountNew) }, 'updateAdmin');
const dbNew = getFirestore(appNew);

const ID_ANTIGUO = "VVYFjlofNJTjUAKgetOYU3E9II42";
const ID_NUEVO = "6LZHLvgNTCaNE1V4usPywuUvpOs1"; 

async function actualizarAdminId() {
  const coleccionesAfectadas = ['clientes', 'movimientos'];

  try {
    console.log(`🔄 Reemplazando adminId antiguo (${ID_ANTIGUO}) por el nuevo (${ID_NUEVO})...\n`);

    for (const colName of coleccionesAfectadas) {
      const snapshot = await dbNew.collection(colName).where('adminId', '==', ID_ANTIGUO).get();

      if (snapshot.empty) {
        console.log(`⚠️ No se encontraron documentos con ese adminId en la colección '${colName}'.`);
        continue;
      }

      console.log(`✍️ Actualizando ${snapshot.size} documentos en '${colName}'...`);
      const batch = dbNew.batch();

      snapshot.docs.forEach((doc) => {
        const docRef = dbNew.collection(colName).doc(doc.id);
        batch.update(docRef, { adminId: ID_NUEVO });
      });

      await batch.commit();
      console.log(`✅ Colección '${colName}' actualizada con éxito.\n`);
    }

    console.log("🎉 ¡Todos los registros han sido actualizados con tu nuevo adminId!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error actualizando el adminId:", error);
    process.exit(1);
  }
}

actualizarAdminId();