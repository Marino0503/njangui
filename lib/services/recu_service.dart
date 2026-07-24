import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/paiement.dart';
import '../utils/formatage.dart';

// Génère et partage un reçu PDF pour un paiement. Purement client (pas de
// dépendance serveur) : les données affichées sont celles déjà stockées
// dans le document Firestore du paiement.
class RecuService {
  static const _violet = PdfColor.fromInt(0xFF7B2D8B);
  static const _vert = PdfColor.fromInt(0xFF2E9E6E);

  static Future<void> partagerRecu(Paiement paiement) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Njangi',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: _violet,
              ),
            ),
            pw.Text(
              'la tontine, sans conflit',
              style: pw.TextStyle(fontSize: 10, color: _violet),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: _violet),
            pw.SizedBox(height: 20),

            pw.Text(
              'REÇU DE PAIEMENT',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Reçu N° ${paiement.id}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),

            _ligne('Tontine', paiement.tontineNom),
            _ligne('Membre', paiement.membreNom),
            _ligne('Date du paiement', Formatage.date(paiement.date)),
            _ligne(
              'Statut',
              paiement.statut == 'paye' ? 'Payé' : 'En retard',
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 12),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Montant',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  Formatage.montant(paiement.montant),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _vert,
                  ),
                ),
              ],
            ),

            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'Reçu généré automatiquement par l\'application Njangi. '
              'Il fait foi de preuve de paiement au sein de la tontine.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'recu_${paiement.tontineNom}_${paiement.id}.pdf',
    );
  }

  static pw.Widget _ligne(String titre, String valeur) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(titre, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(
            valeur,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
