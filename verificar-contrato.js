// Uso: node verificar-contrato.js http://localhost:3000
//      node verificar-contrato.js http://SU-IP-PUBLICA
const base = process.argv[2];
if (!base) {
  console.log('Uso: node verificar-contrato.js http://DIRECCION[:PUERTO]');
  process.exit(1);
}

const casos = [
  { ruta: '/salud', codigo: 200, validar: (j) => j.estado === 'ok' },
  { ruta: '/equipo', codigo: 200, validar: (j) => typeof j.equipo === 'string' && Array.isArray(j.integrantes) },
  { ruta: '/notas', codigo: 200, validar: (j) => j.promedio === 3.625 && j.aprobado === true },
  { ruta: '/loquesea', codigo: 404, validar: (j) => j.error === 'Ruta no encontrada' },
];

async function main() {
  let fallos = 0;
  for (const caso of casos) {
    const r = await fetch(base + caso.ruta);
    const texto = await r.text();
    let ok = r.status === caso.codigo;
    try { ok = ok && caso.validar(JSON.parse(texto)); } catch { ok = false; }
    if (!ok) fallos++;
    console.log(`${ok ? 'OK   ' : 'FALLA'} ${caso.ruta}  ->  ${r.status}  ${texto}`);
  }
  console.log(fallos === 0 ? '\nContrato cumplido: las 4 rutas responden como antes.' : `\n${fallos} ruta(s) rompen el contrato.`);
  process.exit(fallos === 0 ? 0 : 1);
}
main();
