/// Puerta para invitados (decisión 5 del plan 5A.3): el tutorial y los dos
/// primeros casos de La Mansión son gratis; el resto de la campaña y el reto
/// diario exigen cuenta. El servidor aplica la misma regla (lista en
/// `config/server.freeCaseIds`); esto solo evita llamadas inútiles y pone el
/// candado en la lista.
library;

import '../backend/backend_config.dart' show isServerCaseId;

/// Casos que un invitado puede jugar.
const Set<String> kFreeCaseIds = {'mansion-01', 'mansion-02'};

/// true si abrir [caseId] exige haberse registrado. El tutorial y el banco de
/// pruebas no pasan por el servidor y nunca lo exigen. El reto diario
/// (`reto-*`) siempre lo exige.
bool requiresRegistration(String caseId) =>
    isServerCaseId(caseId) && !kFreeCaseIds.contains(caseId);
