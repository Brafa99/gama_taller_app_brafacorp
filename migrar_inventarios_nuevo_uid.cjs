const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccountOld = require('./serviceAccountKeyOld.json');
const serviceAccountNew = require('./serviceAccountKeyNew.json');

const appOld = initializeApp({ credential: cert(serviceAccountOld) }, 'oldFinal');
const dbOld = getFirestore(appOld);

const appNew = initializeApp({ credential: cert(serviceAccountNew) }, 'newFinal');
const dbNew = getFirestore(appNew);

const ID_ANTIGUO = "VVYFjlofNJTjUAKgetOYU3E9II42";
const ID_NUEVO = "6LZHLvgNTCaNE1V4usPywuUvpOs1"; // Tu UID actual en el proyecto nuevo

async function migrarForzadoFinal() {
  try {
    console.log(`🚀 Leyendo de forma directa la ruta exacta: inventarios/${ID_ANTIGUO}...`);
    
    const docOldRef = dbOld.collection('inventarios').doc(ID_ANTIGUO);
    const docOldSnap = await docOldRef.get();

    if (!docOldSnap.exists) {
      console.error("❌ El documento no existe o la cuenta de servicio no tiene acceso.");
      process.exit(1);
    }

    console.log("✅ ¡Documento raíz encontrado correctamente en el proyecto antiguo!");

    // 1. Crear el contenedor en el proyecto nuevo con tu NUEVO UID
    const docNewRef = dbNew.collection('inventarios').doc(ID_NUEVO);
    await docNewRef.set(docOldSnap.data() || {});
    console.log(`📁 Contenedor creado en el nuevo proyecto con tu UID: [ ${ID_NUEVO} ]`);

    // 2. Obtener las categorías (accesorios, electricos, motores, aceites, etc.)
    const categoriasSnap = await docOldRef.collection('categorias').get();

    if (categoriasSnap.empty) {
      console.log("⚠️ El documento no tiene subcolecciones de categorías.");
      process.exit(0);
    }

    console.log(`📂 Se encontraron ${categoriasSnap.size} categorías. Migrando productos...`);

    for (const catDoc of categoriasSnap.docs) {
      const catId = catDoc.id;
      const catNewRef = docNewRef.collection('categorias').doc(catId);
      
      await catNewRef.set(catDoc.data() || {});
      console.log(`   📂 Procesando categoría: [ ${catId} ]`);

      // 3. Obtener los productos dentro de cada categoría
      const productosSnap = await catDoc.ref.collection('productos').get();

      if (productosSnap.empty) {
        console.log(`      ↳ La categoría '${catId}' no tiene productos.`);
        continue;
      }

      for (const prodDoc of productosSnap.docs) {
        await catNewRef.collection('productos').doc(prodDoc.id).set(prodDoc.data());
      }
      console.log(`      ✅ ${productosSnap.size} productos migrados en '${catId}'.`);
    }

    console.log("\n🎉 ¡INVENTARIO MIGRADO EXITOSAMENTE AL 100%!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error crítico:", error);
    process.exit(1);
  }
}

migrarForzadoFinal();