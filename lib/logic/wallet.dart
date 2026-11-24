import 'dart:math';

/// Una cantidad de monedas al azar, de [min] a [max] (las dos incluidas).
class CoinRange {
  const CoinRange(this.min, this.max);

  /// No da monedas (para capítulos de prueba).
  static const none = CoinRange(0, 0);

  final int min;
  final int max;

  int roll(Random random) =>
      max <= min ? min : min + random.nextInt(max - min + 1);
}

/// Bono de bienvenida: [coins] monedas por cada [everySteps] pasos ya
/// caminados, redondeado hacia abajo.
class WelcomeBonus {
  const WelcomeBonus({required this.coins, required this.everySteps});

  final int coins;
  final int everySteps;

  int amountFor(int totalSteps) => max(0, totalSteps) ~/ everySteps * coins;
}

enum CoinNoticeKind { daily, welcome }

/// Aviso de monedas recibidas que todavía no se mostró. Se guarda en la
/// partida: si la app se cierra antes de verlo, aparece al volver.
class CoinNotice {
  const CoinNotice(this.kind, this.amount);

  final CoinNoticeKind kind;
  final int amount;

  Map<String, Object?> toJson() => {'kind': kind.name, 'amount': amount};

  static CoinNotice fromJson(Map<String, dynamic> json) => CoinNotice(
    CoinNoticeKind.values.byName(json['kind'] as String),
    json['amount'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is CoinNotice && other.kind == kind && other.amount == amount;

  @override
  int get hashCode => Object.hash(kind, amount);

  @override
  String toString() => 'CoinNotice(${kind.name}, $amount)';
}

/// Las monedas de la partida y los bonos ya cobrados.
class Wallet {
  const Wallet({
    this.coins = 0,
    this.dailyBonusDate,
    this.welcomeBonusPaid = false,
    this.notices = const [],
  });

  static const initial = Wallet();

  final int coins;

  /// Último día (aaaa-mm-dd, fecha local) en que se cobró el bono diario.
  final String? dailyBonusDate;

  /// Si ya se cobró el bono de bienvenida a la 1.2.0 (solo partidas de
  /// antes de esa versión).
  final bool welcomeBonusPaid;

  /// Avisos de monedas que todavía no se vieron, en orden.
  final List<CoinNotice> notices;

  Wallet _copy({
    int? coins,
    String? dailyBonusDate,
    bool? welcomeBonusPaid,
    List<CoinNotice>? notices,
  }) => Wallet(
    coins: coins ?? this.coins,
    dailyBonusDate: dailyBonusDate ?? this.dailyBonusDate,
    welcomeBonusPaid: welcomeBonusPaid ?? this.welcomeBonusPaid,
    notices: notices ?? this.notices,
  );

  Wallet add(int amount) => amount <= 0 ? this : _copy(coins: coins + amount);

  /// Lanza un error si no alcanza (la tienda lo revisa antes).
  Wallet spend(int amount) {
    if (amount > coins) throw StateError('No alcanzan las monedas');
    return _copy(coins: coins - amount);
  }

  /// Bono diario: se cobra si [today] es posterior al último día cobrado.
  /// Si se atrasa la hora del celular, no se vuelve a cobrar. Si no
  /// corresponde, devuelve esta misma billetera.
  Wallet claimDaily(String today, CoinRange range, Random random) {
    final last = dailyBonusDate;
    if (last != null && today.compareTo(last) <= 0) return this;
    final amount = range.roll(random);
    return _copy(
      coins: coins + amount,
      dailyBonusDate: today,
      notices: [
        ...notices,
        if (amount > 0) CoinNotice(CoinNoticeKind.daily, amount),
      ],
    );
  }

  /// Bono de bienvenida, según los pasos ya caminados. Se cobra una sola
  /// vez: queda marcado en [welcomeBonusPaid].
  Wallet payWelcome(int totalSteps, WelcomeBonus bonus) {
    if (welcomeBonusPaid) return this;
    final amount = bonus.amountFor(totalSteps);
    return _copy(
      coins: coins + amount,
      welcomeBonusPaid: true,
      notices: [
        ...notices,
        if (amount > 0) CoinNotice(CoinNoticeKind.welcome, amount),
      ],
    );
  }

  /// Ya se mostró el aviso.
  Wallet dismiss(CoinNotice notice) {
    final i = notices.indexWhere((n) => identical(n, notice));
    final at = i >= 0 ? i : notices.indexOf(notice);
    if (at < 0) return this;
    return _copy(notices: [...notices]..removeAt(at));
  }

  Map<String, Object?> toJson() => {
    'coins': coins,
    'dailyBonusDate': dailyBonusDate,
    'welcomeBonusPaid': welcomeBonusPaid,
    'notices': [for (final n in notices) n.toJson()],
  };

  /// Lanza una excepción si el JSON no tiene la forma esperada.
  static Wallet fromJson(Map<String, dynamic> json) => Wallet(
    coins: json['coins'] as int,
    dailyBonusDate: json['dailyBonusDate'] as String?,
    welcomeBonusPaid: json['welcomeBonusPaid'] as bool,
    notices: List.unmodifiable([
      for (final n in json['notices'] as List<dynamic>)
        CoinNotice.fromJson(n as Map<String, dynamic>),
    ]),
  );

  @override
  bool operator ==(Object other) =>
      other is Wallet &&
      other.coins == coins &&
      other.dailyBonusDate == dailyBonusDate &&
      other.welcomeBonusPaid == welcomeBonusPaid &&
      _sameList(other.notices, notices);

  @override
  int get hashCode => Object.hash(
    coins,
    dailyBonusDate,
    welcomeBonusPaid,
    Object.hashAll(notices),
  );

  @override
  String toString() =>
      'Wallet(coins: $coins, daily: $dailyBonusDate, '
      'welcome: $welcomeBonusPaid, notices: $notices)';
}

bool _sameList(List<CoinNotice> a, List<CoinNotice> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
