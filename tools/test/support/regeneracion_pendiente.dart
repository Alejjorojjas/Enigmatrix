// Interruptor temporal (05-11-2026). No es una prueba (no termina en _test).
//
// Las reglas de coherencia de mapa (familias, únicos por habitación,
// habitación permitida) cambiaron el generador. Los 40 casos del Mundo 1
// (10 de campaña + 30 de reto) en app/assets/cases se hicieron con el motor
// anterior y siguen incumpliéndolas hasta que se regeneren con
// `build-plan` y semillas nuevas donde haga falta.
//
// Mientras esto sea true:
//  - la puerta de contenido sobre los assets exime también a la Mansión de
//    las reglas de mapa (el banco de pruebas y el tutorial siempre están
//    exentos), y
//  - las pruebas de "reproducibilidad" (plan -> archivo idéntico) se saltan,
//    porque el generador ya no produce esos archivos.
//
// Quien regenere los casos debe poner esto en false: la prueba
// "el interruptor es coherente" falla si se queda en true con casos ya
// regenerados.
import 'package:enigmatrix_engine/enigmatrix_engine.dart';

const bool kMundo1PendienteDeRegenerar = false;

/// Mundos exentos de las reglas de mapa en la puerta sobre los assets.
Set<String> get mundosExentosDeReglasDeMapa => {
      kBancoDePruebas,
      if (kMundo1PendienteDeRegenerar) kMundoMansion,
    };
