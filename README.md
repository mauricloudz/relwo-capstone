# Relwo — Repositorio Documental Capstone

Repositorio documental del proyecto de título **Relwo**, desarrollado para la asignatura **Portafolio de Título (Capstone - PTY4614)** de la carrera **Ingeniería en Informática** en **Duoc UC, Sede Plaza Norte**.

Este espacio centraliza las evidencias de aprendizaje, actas, entregables técnicos y la documentación de avance del proyecto para la revisión y seguimiento continuo por parte del docente a lo largo del semestre académico.

---

## 👥 Equipo de Trabajo

* **Mauricio Poblete**
* **Tania Sáez**
* **Nayareth Suárez**

---

## 📱 Acerca del Proyecto: Relwo

**Relwo** es una plataforma tecnológica concebida para formalizar, transparentar y asegurar la contratación de servicios y oficios para el hogar (gasfitería, cerrajería, electricidad, limpieza, entre otros).

### Problemática y Propuesta de Valor
En Chile, la contratación de servicios domésticos independientes suele realizarse mediante canales informales sin verificación de identidad ni garantías de cumplimiento. Relwo soluciona este problema mediante:
* **Verificación de prestadores:** Registro y validación de antecedentes de los profesionales para generar confianza en el cliente.
* **Seguridad en las transacciones:** Esquema de pago retenido (*escrow*), donde el dinero permanece bajo custodia y se libera al prestador únicamente cuando ambas partes manifiestan conformidad con el trabajo realizado.
* **Publicación con multioferta:** El cliente publica su necesidad, los maestros verificados de su comuna ofertan y el cliente elige. El precio definitivo se cotiza en terreno y se aprueba antes de pagar; todos los montos se calculan en el servidor.
* **Cobertura por comuna:** Gran Santiago, con 40 comunas visibles y puesta en marcha inicial en cuatro, que se amplía a medida que se suman maestros verificados.

### Arquitectura y Componentes Tecnológicos
* **Aplicación Móvil:** Desarrollada en **Flutter**, con interfaces especializadas para clientes y prestadores de servicios.
* **Panel Web de Administración:** Desarrollado en **Angular**, orientado a la supervisión operativa, resolución de controversias y validación de perfiles.
* **Servicio Backend & API REST:** Construido con **NestJS** y **TypeScript**.
* **Base de Datos:** Motor relacional **PostgreSQL**.
* **Integración de Pagos:** Conexión con pasarela de pagos en entorno de pruebas implementando retención de fondos.

---

## 📂 Estructura del Repositorio

El repositorio se encuentra estructurado en tres fases secuenciales correspondientes al ciclo académico, manteniendo en cada una la separación estricta entre evidencias grupales e individuales:

```text
relwo-capstone/
├── Fase 1/                         # Definición y Planificación del Proyecto (Semanas 1 a 4)
│   ├── Evidencias grupales/        # Definición del proyecto APT, Carta Gantt, presentación y prototipo navegable
│   ├── Evidencias individuales/    # Autoevaluaciones de competencias (1.1, 1.3) y diarios de reflexión (1.2)
│   └── README.md                   # Detalle e información de la Fase 1
│
├── Fase 2/                         # Desarrollo y Ejecución (Semanas 5 a 14)
│   ├── Evidencias grupales/        # Guías 2.4 (Desarrollo Proyecto APT) y 2.6 (Informe Final) completadas
│   ├── Evidencias individuales/    # Diarios de reflexión y autoevaluaciones de cada integrante
│   ├── Evidencias Proyecto/
│   │   ├── Presentacion Proyecto/          # Presentación de avance de la Fase 2
│   │   ├── Evidencias de Documentacion/    # Visión, RACI, Product Backlog, carta Gantt, fichas de sprints, DAS, ERS, diseño y cambios de alcance
│   │   └── Evidencias de Sistema/          # Base de datos (modelo, diagramas MER/MERE/relacional y scripts SQL); aplicación reservada para la Fase 3
│   └── README.md                   # Detalle e información de la Fase 2
│
└── Fase 3/                         # Cierre y Evaluación (Semanas 15 a 18)
    ├── Evidencias grupales/        # Pruebas en dispositivos físicos, despliegue en entorno de pruebas y presentación final
    ├── Evidencias individuales/    # Autoevaluación final de competencias y reflexiones de cierre
    └── README.md                   # Detalle e información de la Fase 3
```

---

## 🔗 Entregables y Recursos Destacados

* [Prototipo navegable web](Fase%201/Evidencias%20grupales/Prototipo%20navegable%20web.md) — Documento con acceso al prototipo interactivo de navegación de flujos.
* [Carta Gantt del Proyecto](Fase%201/Evidencias%20grupales/Carta_Gantt_Relwo.xlsx) — Planificación semestral de actividades, hitos, asignación de responsabilidades y dependencias.
* [Guía de Definición del Proyecto APT](Fase%201/Evidencias%20grupales/1.5_GuiaEstudiante_Fase%201_Definicion%20Proyecto%20APT) — Fundamentación del proyecto, alcance técnico, pertinencia y competencias asociadas.
* [Presentación de avance de la Fase 2](Fase%202/Evidencias%20Proyecto/Presentacion%20Proyecto/Relwo_Fase2_Presentacion.pptx) — Estado del proyecto al cierre del Sprint 7: producto, metodología, seguimiento y próximos pasos.
* [Documento de Visión](Fase%202/Evidencias%20Proyecto/Evidencias%20de%20Documentacion/01_Documento_de_Vision.docx) — Qué problema resuelve Relwo, para quién, qué incluye el MVP y cómo se mide su éxito.
* [Resumen de sprints](Fase%202/Evidencias%20Proyecto/Evidencias%20de%20Documentacion/05_Sprints/00_Resumen_de_Sprints.docx) — Cronograma real, compromisos y entregas de los Sprints 1 a 8, con una ficha por sprint en la misma carpeta.
* [Modelo de datos](Fase%202/Evidencias%20Proyecto/Evidencias%20de%20Sistema/Base%20de%20datos/Modelo_de_Datos.docx) — Dominios, entidades y decisiones de diseño de la base, junto a los diagramas y scripts.

---

## 📌 Convenciones de Entrega

* **Evidencias grupales:** Guías institucionales completadas y presentaciones consensuadas por el equipo.
* **Evidencias Proyecto (Fase 2):** Documentación de gestión y técnica del proyecto, escrita para el seguimiento del docente guía: en lenguaje natural, sin referencias a código ni nombres de terceros.
* **Evidencias individuales:** Formatos institucionales correspondientes a las entregas de cada integrante (`[Nombre]_[Apellido]-[Código]_[Asignatura]_[Tipo].docx`).
