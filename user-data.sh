#!/bin/bash
dnf install -y nodejs
mkdir -p /opt/api
cat > /opt/api/server.js <<'FIN'
const http = require('http');

// ---------- Configuración (cada valor con nombre, una sola vez) ----------
const PUERTO = process.env.PORT || 80;
const NOTA_MINIMA_APROBATORIA = 3.0;

const CODIGO_OK = 200;
const CODIGO_NO_ENCONTRADO = 404;
const CABECERAS_JSON = { 'Content-Type': 'application/json; charset=utf-8' };

// ---------- Datos: de dónde salen las notas y quién es el equipo ----------
const notasDelCurso = [4.5, 3.5, 2.5, 4.0];

const datosDelEquipo = {
  equipo: 'Equipo 77',
  integrantes: ['Andres David Bustamante'],
};

// ---------- Lógica: reglas puras, no saben nada de HTTP ----------
function calcularPromedio(notas) {
  const suma = notas.reduce((acumulado, nota) => acumulado + nota, 0);
  return suma / notas.length;
}

function estaAprobado(promedio) {
  return promedio >= NOTA_MINIMA_APROBATORIA;
}

function resumirNotas(notas) {
  const promedio = calcularPromedio(notas);
  return { promedio: promedio, aprobado: estaAprobado(promedio) };
}

// ---------- Presentación: arma y envía la respuesta, no calcula ----------
function responder(res, codigo, datos) {
  res.writeHead(codigo, CABECERAS_JSON);
  res.end(JSON.stringify(datos));
}

const rutas = {
  '/salud': () => ({ estado: 'ok' }),
  '/equipo': () => datosDelEquipo,
  '/notas': () => resumirNotas(notasDelCurso),
};

function manejarPeticion(req, res) {
  const obtenerDatos = rutas[req.url];

  if (!obtenerDatos) {
    responder(res, CODIGO_NO_ENCONTRADO, { error: 'Ruta no encontrada' });
    return;
  }
  responder(res, CODIGO_OK, obtenerDatos());
}

const servidor = http.createServer(manejarPeticion);
servidor.listen(PUERTO);
FIN
cat > /etc/systemd/system/api.service <<'FIN'
[Unit]
Description=API del equipo
After=network.target
[Service]
ExecStart=/usr/bin/node /opt/api/server.js
Restart=always
[Install]
WantedBy=multi-user.target
FIN
systemctl daemon-reload
systemctl enable --now api
