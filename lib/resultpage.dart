import 'dart:ui';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'models/year_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ResultPage extends StatefulWidget {
  final double totalSal;
  final String? ssfController;
  final String? epfController;
  final String? citController;
  final String? insController;
  final TaxPayerType selectedValue;
  final FiscalYear selectedFiscalYear;

  ResultPage(
      {Key? key,
      required this.totalSal,
      required this.ssfController,
      required this.epfController,
      required this.citController,
      required this.insController,
      required this.selectedValue,
      required this.selectedFiscalYear})
      : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  double get totalSal => widget.totalSal;

  String? get ssf => widget.ssfController;

  String? get epf => widget.epfController;

  String? get cit => widget.citController;

  String? get ins => widget.insController;

  List<SlabRule> taxSlabRules = [];
  EligibleDeductionAmount data = EligibleDeductionAmount(
      taxableIncome: '',
      accessibleins: '',
      accessiblessfcitpf: '',
      accessiblecitpf: '');

  final key1 = GlobalKey();
  final key2 = GlobalKey();

  Future<void> fetchData() async {
    final url = Uri.parse(
        'https://www.salarytaxnepal.com/SalaryTaxService.asmx/getEligibleDeduction');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      "taxPayerTypeid": widget.selectedValue.id,
      "fiscalYear": widget.selectedFiscalYear.id,
      "totalSal": totalSal,
      "cit": cit ?? 0,
      "epf": epf ?? 0,
      "ins": ins ?? 0,
      "ssf": ssf ?? 0
    });
    try {
      final response = await http.post(url, headers: headers, body: body);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedData =
            json.decode(response.body)['d'] as Map<String, dynamic>;
        setState(() {
          data = EligibleDeductionAmount.fromJson(parsedData);
        });
      } else {
        throw Exception('Failed to fetch eligible deduction');
      }
    } catch (error) {
      // handle the error here, for example:
      print('Error fetching tax slab rule: $error');
    }
  }

  Future<void> fetchTaxSlabRule() async {
    final url = Uri.parse(
        'https://www.salarytaxnepal.com/SalaryTaxService.asmx/getTaxRule');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "taxPayerTypeid": widget.selectedValue.id,
      "fiscalYear": widget.selectedFiscalYear.id,
      "totalSal": totalSal,
      "cit": cit ?? 0,
      "epf": epf ?? 0,
      "ins": ins ?? 0,
      "ssf": ssf ?? 0
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body)['d'];

        SlabRuleResponse slabRuleResponse = SlabRuleResponse.fromJson(data);
        setState(() {
          taxSlabRules = slabRuleResponse.taxSlabRule;
        });
      } else {
        throw Exception('Failed to fetch tax slab rules');
      }
    } catch (error) {
      // handle the error here, for example:
      print('Error fetching tax slab rule: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchTaxSlabRule();
  }

  @override
  Widget build(BuildContext context) {
    double totalDeduction = 0.0;

      final ssfcitpf = double.tryParse(data.accessiblessfcitpf) ?? 0;
      final totins = double.tryParse(data.accessibleins) ?? 0;
      totalDeduction = ssfcitpf + totins;

      String taxLiability = 'Rs.${NumberFormat.decimalPattern('hi').format(taxSlabRules.fold<double>(0.0, (sum, rule) => sum + rule.taxLiability))}';
      String income = 'Rs.${NumberFormat.decimalPattern('hi').format(taxSlabRules.fold<double>(0.0, (sum, rule) => sum + rule.assesibleIncome))}';
      String monthly = 'Rs.${NumberFormat.decimalPattern('hi').format((taxSlabRules.fold<double>(0.0, (sum, rule) => sum + rule.taxLiability))/12)}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF286090),
        title: const Text("Tax Liability"),
        centerTitle: true,
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SingleChildScrollView(
                      child: RepaintBoundary(
                        key: key1,
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Color(0xFF286090)),
                          dataRowColor: MaterialStateColor.resolveWith(
                              (states) => const Color(0xFFD5E7FF)),
                          decoration: BoxDecoration(border: Border.all()),
                          columns: const <DataColumn>[
                            DataColumn(label: Text('Data', style: TextStyle(fontSize: 16, color: Colors.white),)),
                            DataColumn(numeric: true,label: Text('Amount', style: TextStyle(fontSize: 16, color: Colors.white),)),
                          ],
                          rows: <DataRow>[
                            DataRow(
                              cells: <DataCell>[
                                const DataCell(Text('Total Income(TI):')),
                                DataCell(Text('Rs.${totalSal.toStringAsFixed(2)}')),
                              ],
                            ),
                            DataRow(cells: <DataCell>[
                              const DataCell(
                                  Text('Sum of SSF, EPF, and CIT(SSF+EPF+CIT):')),
                              DataCell(Text('Rs.${data.accessiblessfcitpf}')),
                            ]),
                            DataRow(
                              cells: <DataCell>[
                                const DataCell(Text('Insurance:')),
                                DataCell(Text('Rs.${data.accessibleins}')),
                              ],
                            ),
                            DataRow(
                              cells: <DataCell>[
                                const DataCell(Text('Total Deduction(TD):')),
                                DataCell(Text(
                                  'Rs.${totalDeduction.toStringAsFixed(2)}',
                                )),
                              ],
                            ),
                            DataRow(cells: <DataCell>[
                              const DataCell(Text('Net Assessable(TI-TD):')),
                              DataCell(Text('Rs.${data.taxableIncome}'))
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    taxSlabRules.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              child: RepaintBoundary(
                                key: key2,
                                child: DataTable(
                                  columnSpacing: 29.0,
                                  headingRowColor: MaterialStateColor.resolveWith(
                                      (states) => Color(0xFF286090)),
                                  dataRowColor: MaterialStateColor.resolveWith(
                                      (states) => const Color(0xFFD5E7FF)),
                                  decoration: BoxDecoration(border: Border.all()),
                                  columns:  [
                                    DataColumn(numeric: true,
                                        label: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Accessible', style: TextStyle(fontSize: 16, color: Colors.white),),
                                            Text('Income(Rs.)', style: TextStyle(fontSize: 16, color: Colors.white),)
                                          ],
                                        )),
                                    DataColumn(numeric: true,
                                        label: Text('Rate(%)', style: TextStyle(fontSize: 16, color: Colors.white))),
                                    DataColumn(numeric: true,
                                        label: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Tax', style: TextStyle(fontSize: 16, color: Colors.white),),
                                            Text('Liability(Rs.)', style: TextStyle(fontSize: 16, color: Colors.white),)
                                          ],
                                        )),
                                  ],
                                  rows: taxSlabRules.map((taxSlabRule) {
                                    return DataRow(cells: [
                                      DataCell(Text(
                                        NumberFormat.decimalPattern('hi').format(taxSlabRule.assesibleIncome),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right, // Align text to the right
                                      )),
                                      DataCell(Text(
                                        taxSlabRule.rate.toString(),
                                        textAlign: TextAlign.right, // Align text to the right
                                      )),
                                      DataCell(Text(
                                        NumberFormat.decimalPattern('hi').format(taxSlabRule.taxLiability),
                                        textAlign: TextAlign.right, // Align text to the right
                                      )),
                                    ]);
                                  }).toList()
                                    ..add(DataRow(cells: [
                                      DataCell(
                                        Text(
                                          income,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.0,
                                              color: Color(0xFF286090)),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      const DataCell(Text('')),
                                      DataCell(Text(
                                        taxLiability,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                            color: Color(0xFF286090)),
                                        textAlign: TextAlign.right,
                                      )),
                                    ])),
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Text('Net Tax Liability (Monthly): $monthly', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Text('Net Tax Liability (Yearly) : $taxLiability', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                    const SizedBox(
                      height: 30.0,
                    ),
                    Row(
                      children: const [Text("*This is rough estimation")],
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(onPressed: _printDataTables, child: Icon(Icons.print)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  Future<void> _printDataTables() async {
    double totalDeduction = 0.0;

    final ssfcitpf = double.tryParse(data.accessiblessfcitpf) ?? 0;
    final totins = double.tryParse(data.accessibleins) ?? 0;
    totalDeduction = ssfcitpf + totins;

    String taxLiability = 'Rs.${NumberFormat.decimalPattern('hi').format(taxSlabRules.fold<double>(0.0, (sum, rule) => sum + rule.taxLiability))}';
    String income = 'Rs.${NumberFormat.decimalPattern('hi').format(taxSlabRules.fold<double>(0.0, (sum, rule) => sum + rule.assesibleIncome))}';
    String monthly = 'Rs.${NumberFormat.decimalPattern('hi').format((taxSlabRules.fold<double>(0.0, (sum, rule) => sum + rule.taxLiability))/12)}';

    final doc = pw.Document();
    final image = await imageFromAssetBundle('images/logo.png');

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        pw.Table.fromTextArray(
          border: const pw.TableBorder(horizontalInside: pw.BorderSide()),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: PdfColors.white,
          ),
          cellStyle: const pw.TextStyle(fontSize: 14),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blue,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          data: [
            ['Data', 'Amount'],
            ['Total Income(TI):', 'Rs.${totalSal.toStringAsFixed(2)}'],
            ['Sum of SSF, EPF, and CIT(SSF+EPF+CIT):', 'Rs.${data.accessiblessfcitpf}'],
            ['Insurance:', 'Rs.${data.accessibleins}'],
            ['Total Deduction(TD):', 'Rs.${totalDeduction.toStringAsFixed(2)}'],
            ['Net Assessable(TI-TD):', 'Rs.${data.taxableIncome}'],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          border: const pw.TableBorder(horizontalInside: pw.BorderSide()),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: PdfColors.white,
          ),
          cellStyle: const pw.TextStyle(fontSize: 14),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blue,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          data: [
            ['Accessible Income(Rs.)', 'Rate(%)', 'Tax Liability(Rs.)'],
            ...taxSlabRules.map((rule) => [
              NumberFormat.decimalPattern('hi').format(rule.assesibleIncome),
              '${rule.rate}%',
              NumberFormat.decimalPattern('hi').format(rule.taxLiability),
            ]).toList(),
            [
              income,
              '',
              taxLiability,
            ],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text('Net Tax Liability (Monthly): $monthly', style: pw.TextStyle(fontSize: 16.0, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Net Tax Liability (Yearly) : $taxLiability', style: pw.TextStyle(fontSize: 16.0, fontWeight: pw.FontWeight.bold),),
        pw.SizedBox(height: 30),
        pw.Text('*This is a rough estimation'),
        pw.SizedBox(height: 50),
        pw.Text('Powered By:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Eattendance.com (Online Attendance, leave, and payroll system)'),
        pw.Text('www.eattendance.com'),
        pw.Text('Email: info@eattendance.com'),
        pw.Text('Phone: +977-9851164319'),
        pw.SizedBox(height: 20),
        pw.Image(image),
      ],
    ));

    // await Printing.layoutPdf(
    //   onLayout: (format) => pdf.save(),
    // );

    // await Printing.sharePdf(bytes: await pdf.save(), filename: 'my-document.pdf');

    Navigator.push(context, MaterialPageRoute(builder:
    (context) => PreviewScreen(doc: doc),
    ));

  }
}


class PreviewScreen extends StatelessWidget {
  final pw.Document doc;
  const PreviewScreen({Key? key, required this.doc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_outlined),
        ),
        centerTitle: true,
        title: Text('Preview'),
        backgroundColor: const Color(0xFF286090),
      ),
      body: PdfPreview(
        build: (format) => doc.save(),
        allowSharing: true,
        allowPrinting: true,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: "salarytax.pdf",
      ),
    );
  }
}
