import 'package:Tijaraa/data/model/company_model.dart';
import 'package:Tijaraa/utils/api.dart';
import 'package:Tijaraa/utils/custom_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CompanyState {}

class CompanyInitial extends CompanyState {}

class CompanyFetchProgress extends CompanyState {}

class CompanyFetchSuccess extends CompanyState {
  Company companyData;

  CompanyFetchSuccess(this.companyData);
}

class CompanyFetchFailure extends CompanyState {
  final String errMsg;

  CompanyFetchFailure(this.errMsg);
}

class CompanyCubit extends Cubit<CompanyState> {
  CompanyCubit() : super(CompanyInitial());

  // Remove BuildContext from here
  void fetchCompany() async {
    emit(CompanyFetchProgress());
    try {
      final companyData = await fetchCompanyFromDb();
      emit(CompanyFetchSuccess(companyData));
    } catch (e) {
      // Log the actual error to your console so you can see it!
      debugPrint("CompanyFetch Error: $e");
      emit(CompanyFetchFailure(e.toString()));
    }
  }

  Future<Company> fetchCompanyFromDb() async {
    try {
      var response = await Api.get(
        url: Api.getSystemSettingsApi,
        queryParameters: {},
      );

      if (response[Api.error] == false) {
        // Pass the 'data' Map directly to your model's fromJson constructor
        return Company.fromJson(response['data']);
      } else {
        throw CustomException(response[Api.message] ?? "Error fetching data");
      }
    } catch (e) {
      debugPrint("Parsing Error: $e");
      rethrow;
    }
  }
}
