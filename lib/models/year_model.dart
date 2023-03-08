import 'dart:convert';

//FiscalYear Model
class FiscalYear {
  final int id;
  final String name;

  FiscalYear({required this.id, required this.name});

  factory FiscalYear.fromJson(Map<String, dynamic> json) {
    return FiscalYear(
      id: int.parse(json['YearId']),
      name: json['Year'],
    );
  }
}

//TaxPayerType Model
class TaxPayerType {
  final String id;
  final String type;

  TaxPayerType({required this.id, required this.type});

  factory TaxPayerType.fromJson(Map<String, dynamic> json) {
    return TaxPayerType(
        id: json['TaxPayerTypeID'],
        type: json['TaxPayerType']);
  }
}

// EligibleDeductionAmount model
class EligibleDeductionAmount {
  final String taxableIncome;
  final String accessibleins;
  final String accessiblessfcitpf;
  final String accessiblecitpf;

  EligibleDeductionAmount({
    required this.taxableIncome,
    required this.accessibleins,
    required this.accessiblessfcitpf,
    required this.accessiblecitpf,
  });

  factory EligibleDeductionAmount.fromJson(Map<String, dynamic> json) {
    return EligibleDeductionAmount(
      taxableIncome: json['taxableIncome'],
      accessibleins: json['accessibleins'],
      accessiblessfcitpf: json['accessiblessfcitpf'],
      accessiblecitpf: json['accessiblecitpf'],
    );
  }
}

//TaxSlabRule Model
class SlabRuleResponse {
  String status;
  String message;
  List<SlabRule> taxSlabRule;

  SlabRuleResponse({required this.status, required this.message, required this.taxSlabRule});

  factory SlabRuleResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> taxSlabRuleJson = jsonDecode(json['taxSlabRule']);
    List<SlabRule> taxSlabRule = taxSlabRuleJson.map((e) => SlabRule.fromJson(e)).toList();

    return SlabRuleResponse(
      status: json['status'],
      message: json['message'],
      taxSlabRule: taxSlabRule,
    );
  }
}


class SlabRule {
  double assesibleIncome;
  double rate;
  double taxLiability;

  SlabRule({required this.assesibleIncome, required this.rate, required this.taxLiability});

  factory SlabRule.fromJson(Map<String, dynamic> json) {
    return SlabRule(
      assesibleIncome: double.parse(json['AssesibleIncome']),
      rate: double.parse(json['Rate']),
      taxLiability: double.parse(json['TaxLiability']),
    );
  }
}