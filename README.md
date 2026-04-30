# HSI-Meat-Composition

Este repositorio contiene un script de MATLAB diseñado para el procesamiento y análisis de imágenes hiperespectral (HSI) en el rango VISNIR, orientado específicamente al control de calidad en la industria cárnica. El objetivo principal es la cuantificación y mapeo de componentes (Novilla, Cerdo y Tocino) en muestras complejas, como hamburguesas, utilizando técnicas de quimiometría avanzada.

Características Principales:
Calibración Espectral Completa: Implementa una corrección en reflectancia utilizando blancos de referencia (SRS-99) y una calibración del eje de longitud de onda (nm) mediante ajuste polinomial de segundo grado basado en el estándar WCS-MC-020.  

Preprocesamiento de Datos: Incluye normalización SNV (Standard Normal Variate) para eliminar variaciones de scattering y efectos de escala de intensidad en los espectros.  

Modelado Predictivo (PLS): Utiliza Regresión por Mínimos Cuadrados Parciales (PLS) con selección automática del número óptimo de componentes mediante validación cruzada Leave-One-Out (LOO-CV).  

Segmentación y Filtrado Robusto: Incorpora una máscara de fondo para excluir píxeles no pertenecientes a la muestra y un filtrado de píxeles anómalos basado en la suma de predicciones para garantizar la fiabilidad del análisis global. 

Visualización de Resultados: Genera mapas de concentración espacial para cada componente y proporciona métricas de calidad como $R^2$ y RMSE tanto en entrenamiento como en validación.  

El script espera una estructura de archivos específica que incluye cubos HSI de muestras de carne, discos de calibración y espectros de referencia del fabricante.
