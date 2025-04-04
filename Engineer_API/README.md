# Challenge Engineer - API

## 📌 Objetivo
Desarrollar una aplicación que consuma cotizaciones de monedas desde una API pública.
Normalice los datos obtenidos y los almacene en un archivo plano (`.csv` o `.txt`) para futuras consultas.

---

## 🚀 Cómo ejecutar el script
1. Clonar o descargar repositorio.
2. Asegurate de tener Python 3.8 o superior instalado.
3. Instalar dependencias necesarias
  ```bash pip install requests ```
4. Ejecutá el script principal desde consola:
  ```bash python main.py ```

5. El script te pedirá que selecciones:
   - Qué monedas querés importar (una o más de):
     - `usd-brl` → Dólar con Real brasileño
     - `btc-usd` → Bitcoin con Dólar
     - `ars-usd` → Peso Argentino con Dólar
   - En qué formato querés guardar los datos:
     - CSV
     - TXT (archivo plano delimitado por comas)
   - Cada respuesta debera ser el numero de orden
   
6. El archivo generado se guarda en la carpeta `output/` con el nombre:

```
output/datos_monedas.csv  o  output/datos_monedas.txt
```

---

## 🧱 Estructura de los datos

El archivo generado contiene una fila por cotización, con los siguientes campos normalizados:

| Campo            | Descripción                             |
|------------------|------------------------------------------|
| `moneda_base`    | Código de la moneda de origen (ej. USD) |
| `moneda_destino` | Código de la moneda destino (ej. BRL)   |
| `valor_compra`   | Valor de compra                         |
| `valor_venta`    | Valor de venta                          |
| `fecha_hora`     | Fecha y hora en formato UTC (`YYYY-MM-DD HH:mm:ss`) |

---

## 🛠️ Tecnologías utilizadas

- **Python 3** como lenguaje principal.
- **requests** para hacer llamados HTTP a la API de monedas.
- **csv** para generar archivos de salida.
- **datetime** para normalizar la fecha/hora.
- **os** para gestionar rutas de archivos y asegurar la existencia de la carpeta `output`.

---

## 📁 Estructura del proyecto

```
Engineer_API/
├── main.py                  # Script principal (interactivo)
├── extraccion_monedas.py    # Lógica de extracción, normalización y guardado
├── requirements.txt         # Dependencias del proyecto
├── output/                  # Carpeta donde se guardan los archivos generados
│   └── datos_monedas.csv
└── README.md                # Documentación
```