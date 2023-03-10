import 'package:flutter/material.dart';
import 'models/year_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
  //
  // String? get tax => widget.selectedValue;
  //
  // String? get year => widget.selectedFiscalYear;

  List<SlabRule> taxSlabRules = [];
  EligibleDeductionAmount data = EligibleDeductionAmount(
      taxableIncome: '',
      accessibleins: '',
      accessiblessfcitpf: '',
      accessiblecitpf: '');

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
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.blue.shade500),
                        dataRowColor: MaterialStateColor.resolveWith(
                            (states) => const Color(0xFFD5E7FF)),
                        decoration: BoxDecoration(border: Border.all()),
                        columns: const <DataColumn>[
                          DataColumn(label: Text('Data')),
                          DataColumn(numeric: true,label: Text('Amount')),
                        ],
                        rows: <DataRow>[
                          DataRow(
                            cells: <DataCell>[
                              const DataCell(Text('Total Income(TI):')),
                              DataCell(Text('Rs.${totalSal.toStringAsFixed(1)}')),
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
                                'Rs.${totalDeduction.toStringAsFixed(1)}',
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
                    const SizedBox(height: 20),
                    taxSlabRules.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 28.5,
                              headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.blue.shade500),
                              dataRowColor: MaterialStateColor.resolveWith(
                                  (states) => const Color(0xFFD5E7FF)),
                              decoration: BoxDecoration(border: Border.all()),
                              columns: const [
                                DataColumn(numeric: true,
                                    label: Text('Accessible Income(Rs.)')),
                                DataColumn(numeric: true,
                                    label: Text('Rate(%)')),
                                DataColumn(numeric: true,
                                    label: Text('Tax Liability(Rs.)')),
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
                                          color: Colors.blueAccent),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const DataCell(Text('')),
                                  DataCell(Text(
                                    taxLiability,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                        color: Colors.blueAccent),
                                    textAlign: TextAlign.right,
                                  )),
                                ])),
                            ),
                          ),
                    const SizedBox(
                      height: 3.0,
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
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
