const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccountOld = require('./serviceAccountKeyOld.json');
const serviceAccountNew = require('./serviceAccountKeyNew.json');

const appOld = initializeApp({ credential: cert(serviceAccountOld) }, 'oldOrd');
const dbOld = getFirestore(appOld);

const appNew = initializeApp({ credential: cert(serviceAccountNew) }, 'newOrd');
const dbNew = getFirestore(appNew);

async function migrarOrdenesDeClientes() {
  try {
    console.log("🚀 Buscando subcolecciones 'ordenes' dentro de 'clientes'...\n");
    const clientesOld = await dbOld.collection('clientes').get();

    for (const clienteDoc of clientesOld.docs) {
      const ordenesSnap = await clienteDoc.ref.collection('ordenes').get();

      if (!ordenesSnap.empty) {
        console.log(`👤 Cliente ${clienteDoc.id}: migrando ${ordenesSnap.size} órdenes...`);
        for (const ordenDoc of ordenesSnap.docs) {
          await dbNew
            .collection('clientes')
            .doc(clienteDoc.id)
            .collection('ordenes')
            .doc(ordenDoc.id)
            .set(ordenDoc.data());
        }
      }
    }

    console.log("\n🎉 ¡Todas las órdenes de los clientes fueron migradas con éxito!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

migrarOrdenesDeClientes();