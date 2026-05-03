class Formatage {
  // Formate un montant : 10000 → "10 000 FCFA"
  static String montant(double montant) {
    final parts = montant.toStringAsFixed(0).split('');
    String result = '';
    int count = 0;

    for (int i = parts.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = ' $result';
      }
      result = parts[i] + result;
      count++;
    }
    return '$result FCFA';
  }

  // Formate une date : DateTime → "3 Mai"
  static String date(DateTime date) {
    const mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${date.day} ${mois[date.month - 1]}';
  }

  // Formate un numéro de téléphone
  static String telephone(String tel) {
    if (tel.length < 4) return tel;
    if (tel.startsWith('+237') && tel.length == 13) {
      return '${tel.substring(0, 4)} ${tel.substring(4, 7)} ${tel.substring(7, 10)} ${tel.substring(10)}';
    }
    return tel;
  }
}
