/// Enums stored in the database by name. Never rename a value: rows on the
/// phone and in the backup hold these names.
library;

enum Crop {
  areca('A'),
  coconut('C'),
  pepper('P'),
  banana('B');

  const Crop(this.codeLetter);
  final String codeLetter;
}

enum Irrigation { sprinkler, drip, hose, none }

enum WorkerRole { climber, sprayer, peeler, daily, plucker }

enum AttendanceStatus { present, half, absent }

enum RateUnit { day, palm, tree, kg, nut, lump }

enum TxnKind { work, advance, payment }

enum PayMode { cash, upi, bank }

enum LotStage { harvest, drying, peeling, grading, storage, sold }

enum LotEventKind { cover, turn, moisture, pest, note }

enum ArecaGrade { chali, patora, ulliGadde, karigotu, koka }

enum BuyerKind { campco, trader, apmc, other }
