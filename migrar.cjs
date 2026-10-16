const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// 1. Cargar las credenciales de AMBOS proyectos
const serviceAccountOld = require('./serviceAccountKeyOld.json');
const serviceAccountNew = require('./serviceAccountKeyNew.json');

// 2. Inicializar el proyecto ANTIGUO (para leer)
const appOld = initializeApp({
  credential: cert(serviceAccountOld)
}, 'oldProject');
const dbOld = getFirestore(appOld);

// 3. Inicializar el proyecto NUEVO (para escribir)
const appNew = initializeApp({
  credential: cert(serviceAccountNew)
}, 'newProject');
const dbNew = getFirestore(appNew);

// Tus 4 colecciones
const colecciones = ['clientes', 'ganancias_extra', 'movimientos', 'inventarios'];

async function migrarBaseDeDatos() {
  try {
    console.log("🚀 Iniciando migración segura documento por documento...\n");

    for (const colName of colecciones) {
      console.log(`📂 Leyendo colección del proyecto antiguo: [ ${colName} ]...`);
      const snapshot = await dbOld.collection(colName).get();

      if (snapshot.empty) {
        console.log(`⚠️ La colección ${colName} está vacía. Saltando...\n`);
        continue;
      }

      console.log(`✍️ Escribiendo ${snapshot.size} documentos en el nuevo proyecto de forma segura...`);
      
      let count = 0;
      for (const doc of snapshot.docs) {
        const docRef = dbNew.collection(colName).doc(doc.id);
        await docRef.set(doc.data());
        count++;
        process.stdout.write(`   ↳ Documento ${count}/${snapshot.size} migrado\r`);
      }

      console.log(`\n✅ Colección '${colName}' migrada completamente con éxito.\n`);
    }

    console.log("🎉 ¡Todas las colecciones han sido migradas exitosamente sin errores de tiempo!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error durante la migración:", error);
    process.exit(1);
  }
}

migrarBaseDeDatos();