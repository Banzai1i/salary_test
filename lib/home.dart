import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/year_model.dart';
import 'resultpage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum SocialMedia { linkedin, email, twitter, facebook }

class IncomeCalculator extends StatefulWidget {
  const IncomeCalculator({Key? key}) : super(key: key);

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
        _selectedValue = _taxPayerTypes[0];
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
      _selectedFiscalYear = fiscalYears[0];
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

  _launchEmail() {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info@eattendance.com',
      queryParameters: {'subject': '', 'body': ''},
    );
    launchUrl(emailLaunchUri);
  }

  _launchPhone() async {
    final phone = Uri.parse('tel:+9779851190654');
    if (await canLaunchUrl(phone)) {
      await launchUrl(phone);
    } else {
      throw 'Could not launch $phone';
    }
  }

  void _goToResultPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          totalSal: totalSal,
          ssfController: ssfController.text.isEmpty ? null : ssfController.text,
          citController: citController.text.isEmpty ? null : citController.text,
          epfController: epfController.text.isEmpty ? null : epfController.text,
          insController: insController.text.isEmpty ? null : insController.text,
          selectedValue: _selectedValue!,
          selectedFiscalYear: _selectedFiscalYear!,
        ),
      ),
    );
  }

  void _clearFields() {
    setState(() {
      salaryController.text = "";
      bonusController.text = "";
      monthsController.text = "12";
      ssfController.text = "";
      epfController.text = "";
      citController.text = "";
      insController.text = "";
      totalSalController.text = "";
      totalSal = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF286090),
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
                          hint: const Text('Please Select'),
                          items: _taxPayerTypes
                              .map((taxPayerType) =>
                                  DropdownMenuItem<TaxPayerType>(
                                    value: taxPayerType,
                                    child: Text(taxPayerType.type),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
                              labelText: "Tax Payer Type",
                              border: OutlineInputBorder()),
                          onChanged: (value) {
                            setState(() {
                              _selectedValue = value!;
                            });
                          },
                          onSaved: (value) {
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
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10.0),
                            labelText: "Fiscal Year",
                            border: OutlineInputBorder()),
                        onChanged: (value) {
                          setState(() {
                            _selectedFiscalYear = value!;
                          });
                        },
                        onSaved: (value) {
                          _selectedFiscalYear = value;
                        },
                      )),
                    ], //children
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    autofocus: true,
                    controller: salaryController,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
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
                    height: 6.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: bonusController,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        labelText: "Bonus",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    //onChanged: (_) => calculateTotalIncome(),
                  ),
                  const SizedBox(
                    height: 6.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: monthsController,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        labelText: "Number of Months",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid number of months';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 6.0,
                  ),
                  TextFormField(
                    controller: totalSalController,
                    enabled: false,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        labelText: 'Total Salary',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(
                    height: 6.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: ssfController,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        labelText: "Social Security Fund",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(
                    height: 6.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: epfController,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        labelText: "Employee Provident Fund",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(
                    height: 6.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: citController,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        labelText: "Citizen Investment Trust Fund",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(
                    height: 6.0,
                  ),
                  TextFormField(
                    autofocus: true,
                    controller: insController,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        labelText: "Insurance",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF286090)),
                          onPressed: _clearFields,
                          child: const Text('Reset Values')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF449D44)),
                        child: const Text('Calculate'),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            _goToResultPage();
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(
                        child: Text(
                          "Salary tax calculator is designed for calculating tax payable to Nepal government on the salary earned in a given year. The calculation is based on Nepal Government Tax Policy.",
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Row(
                    children: const [
                      Text(
                          "If you have any feedback and suggestion, please write to"),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _launchEmail,
                        child: const Text(
                          "info@eattendance.com",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      const Text(" or call "),
                      InkWell(
                        onTap: _launchPhone,
                        child: const Text(
                          '9851190654.',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildSocialButtons(),
    );
  }

  Widget buildSocialButtons() => Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSocialButton(
              icon: FontAwesomeIcons.squareFacebook,
              color: Color(0xFF0075fc),
              onClicked: () => share(SocialMedia.facebook),
            ),
            buildSocialButton(
              icon: FontAwesomeIcons.twitter,
              color: Color(0xFF1da1f2),
              onClicked: () => share(SocialMedia.twitter),
            ),
            buildSocialButton(
              icon: FontAwesomeIcons.envelope,
              color: Colors.black87,
              onClicked: () => share(SocialMedia.email),
            ),
            buildSocialButton(
              icon: FontAwesomeIcons.linkedin,
              color: Color(0xFF0064c9),
              onClicked: () => share(SocialMedia.linkedin),
            ),
          ],
        ),
      );

  Future share(SocialMedia socialPlatform) async {
    final subject = 'Salary Tax Calculator';
    final text =
        'Use Salary Tax Calculator to calculate yourSalary Tax based on the Nepal Government Tax Policy ';
    final urlShare = Uri.encodeComponent('https://www.salarytaxnepal.com/');

    final urls = {
      SocialMedia.facebook:
          Uri.parse('http://www.facebook.com/sharer.php?u=$urlShare&p[title]=$text'),
      SocialMedia.twitter:
      Uri.parse('http://twitter.com/share?text=$text&url=$urlShare'),
      SocialMedia.email:
      Uri.parse('mailto:?subject=$subject&body=$text\n\n$urlShare'),
      SocialMedia.linkedin:
          Uri.parse('https://www.linkedin.com/shareArticle?mini=true&url=$urlShare&title=$text'),
    };
    final url = urls[socialPlatform]!;

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget buildSocialButton({
    required IconData icon,
    Color? color,
    required VoidCallback onClicked,
  }) =>
      InkWell(
        child: Container(
          width: 64,
          height: 64,
          child: Center(
            child: FaIcon(
              icon,
              color: color,
              size: 30,
            ),
          ),
        ),
        onTap: onClicked,
      );
}
