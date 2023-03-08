import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/year_model.dart';
import 'resultpage.dart';

class IncomeCalculator extends StatefulWidget {
  const IncomeCalculator({super.key});

  @override
  _IncomeCalculatorState createState() => _IncomeCalculatorState();
}

class _IncomeCalculatorState extends State<IncomeCalculator> {
  List<FiscalYear> _fiscalYears = [];
  FiscalYear? _selectedFiscalYear;

  List<TaxPayerType> _taxPayerTypes = [];
  TaxPayerType? _selectedValue;


  var isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTaxPayerTypes();
    _getFiscalYears();
    salaryController.addListener(calculateTotalIncome);
    monthsController.text = "12"; // set default value of Bonus
    bonusController.addListener(calculateTotalIncome);
    monthsController.addListener(calculateTotalIncome);
    totalSalController.text = totalSal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    salaryController.dispose();
    bonusController.dispose();
    monthsController.dispose();
    totalSalController.dispose();
    super.dispose();
  }

  Future<void> _fetchTaxPayerTypes() async {
    final response = await http.post(
      Uri.parse(
          'https://www.salarytaxnepal.com/SalaryTaxService.asmx/getTaxPayer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final taxPayerTypesJson = json.decode(data['d']['taxPayerType']);
      List<TaxPayerType> taxPayerTypes = [];

      for (var taxPayerTypeJson in taxPayerTypesJson) {
        taxPayerTypes.add(TaxPayerType.fromJson(taxPayerTypeJson));
      }

      setState(() {
        _taxPayerTypes = taxPayerTypes;
      });
    } else {
      throw Exception('Failed to fetch tax payer types');
    }
  }

  void _getFiscalYears() async {
    final response = await http.post(
      Uri.parse(
          'https://www.salarytaxnepal.com/SalaryTaxService.asmx/getFiscalYear'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    final jsonData = jsonDecode(response.body);
    final fiscalYearListJson = jsonDecode(jsonData['d']['fiscalYear']) as List;
    List<FiscalYear> fiscalYears = fiscalYearListJson
        .map((fiscalYearJson) => FiscalYear.fromJson(fiscalYearJson))
        .toList();
    setState(() {
      _fiscalYears = fiscalYears;
    });
  }

  final formKey = GlobalKey<FormState>();

  final salaryController = TextEditingController();
  final bonusController = TextEditingController();
  final totalSalController = TextEditingController();
  final monthsController = TextEditingController();
  final ssfController = TextEditingController();
  final epfController = TextEditingController();
  final citController = TextEditingController();
  final insController = TextEditingController();

  double totalSal = 0.0;

  void calculateTotalIncome() {
    final salary = double.tryParse(salaryController.text) ?? 0;
    final months = double.tryParse(monthsController.text) ?? 0;
    final bonus = double.tryParse(bonusController.text) ?? 0;

    setState(() {
      totalSal = (salary * months) + bonus;
      totalSalController.text = totalSal.toStringAsFixed(2);
    });
  }

  void _goToResultPage(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ResultPage(totalSal: totalSal, ssfController: ssfController.text.isEmpty ? null : ssfController.text,
            citController: citController.text.isEmpty ? null : citController.text,
            epfController: epfController.text.isEmpty ? null : epfController.text,
            insController: insController.text.isEmpty ? null : insController.text, selectedValue: _selectedValue!, selectedFiscalYear: _selectedFiscalYear!,),
      ),
    );
  }

  void _clearFields(){
    setState(() {
      salaryController.text ="";
      bonusController.text = "";
      monthsController.text ="";
      ssfController.text ="";
      epfController.text ="";
      citController.text ="";
      insController.text ="";
      totalSalController.text ="";
      totalSal = 0.0;
      _selectedValue = null;
      _selectedFiscalYear = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salary Tax Calculator"),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TaxPayerType>(
                          value: _selectedValue,
                          hint: Text('Please Select'),
                          items: _taxPayerTypes
                              .map((taxPayerType) =>
                                  DropdownMenuItem<TaxPayerType>(
                                    value: taxPayerType,
                                    child: Text(taxPayerType.type),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: "Tax Payer Type",
                              border: OutlineInputBorder()),
                          onChanged: (value) {
                            setState(() {
                              _selectedValue = value!;
                            });
                          },
                          onSaved: (value){
                            _selectedValue = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                          child: DropdownButtonFormField(
                        hint: const Text("Please Select"),
                        value: _selectedFiscalYear,
                        items: _fiscalYears.map((fiscalYear) {
                          return DropdownMenuItem<FiscalYear>(
                            value: fiscalYear,
                            child: Text(fiscalYear.name),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                            labelText: "Fiscal Year",
                            border: OutlineInputBorder()),
                        onChanged: (value) {
                          setState(() {
                            _selectedFiscalYear = value!;
                          });
                        },
                            onSaved: (value){
                          _selectedFiscalYear = value;
                            },
                      )),
                    ], //children
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    autofocus: true,
                    controller: salaryController,
                    decoration: const InputDecoration(
                        labelText: "Monthly Salary",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid salary';
                      }
                      return null;
                    },
                    //onChanged: (_) => calculateTotalIncome(),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: bonusController,
                    decoration: const InputDecoration(
                        labelText: "Bonus", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid bonus';
                      }
                      return null;
                    },
                    //onChanged: (_) => calculateTotalIncome(),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: monthsController,
                    decoration: const InputDecoration(
                        labelText: "Number of Months",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid number of months';
                      }
                      final months = int.tryParse(value);
                      if(months == null || months < 1 || months >12){
                        return 'Please enter a valid number of months (1-12).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    controller: totalSalController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Total Salary',
                      border: OutlineInputBorder()
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: ssfController,
                    decoration: const InputDecoration(
                        labelText: "Social Security Fund",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter a valid amount';
                    //   }
                    //   return null;
                    // },
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: epfController,
                    decoration: const InputDecoration(
                        labelText: "Employee Provident Fund",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter a valid amount';
                    //   }
                    //   return null;
                    // },
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: citController,
                    decoration: const InputDecoration(
                        labelText: "Citizen Investment Trust Fund",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter a valid amount';
                    //   }
                    //   return null;
                    // },
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: insController,
                    decoration: const InputDecoration(
                        labelText: "Insurance", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter a valid amount';
                    //   }
                    //   return null;
                    // },
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          onPressed: _clearFields,
                          child: Text('Reset')),
                      ElevatedButton(
                        child: Text('Calculate'),
                        onPressed: _goToResultPage,
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
