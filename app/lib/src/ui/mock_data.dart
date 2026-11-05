/// DATOS SIMULADOS (DEMO): vidas, racha, puntos y ranking. Se reemplazan por
/// el servidor en la etapa 5. Mientras tanto cada pantalla que los muestra
/// lleva la etiqueta DEMO.
library;

// Las vidas máximas ya no viven aquí: salen de GameConfig.maxLives (H-65).

const mockLives = 4;
const mockNextLife = '23:41';
const mockStreak = 3;
const mockBestStreak = 7;
const mockProtectors = 1;
const mockWeeklyPoints = 1840;
const mockBots = [
  ('Sherlock221B', 2450, '🇬🇧'),
  ('MissMarple', 2210, '🇬🇧'),
  ('Kogoro', 2075, '🇯🇵'),
  ('DetectivePikachu', 1990, '🇯🇵'),
  ('Clouseau', 1720, '🇫🇷'),
  ('Colombo', 1580, '🇺🇸'),
  ('PoirotFan', 1495, '🇧🇪'),
];
