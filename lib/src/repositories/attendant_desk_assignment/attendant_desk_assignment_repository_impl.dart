import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:fe_lab_clinicas_core/fe_lab_clinicas_core.dart';

import 'attendant_desk_assignment_repository.dart';

class AttendantDeskAssignmentRepositoryImpl
    implements AttendantDeskAssignmentRepository {
  final RestClient restClient;

  AttendantDeskAssignmentRepositoryImpl({required this.restClient});

  @override
  Future<Either<RepositoryException, Unit>> startService(int deskNumber) async {
    final result = await _clearDeskByUsr();

    switch (result) {
      case Left(value: final exception):
        return Left(exception);
      case Right():
        await restClient.auth.post(
          '/attendantDeskAssignment',
          data: {
            'user_id': '#userAuthRef',
            'desk_number': deskNumber,
            'date_created': DateTime.now().toIso8601String(),
            'status': 'Available',
          },
        );
        return Right(unit);
    }
  }

  Future<Either<RepositoryException, Unit>> _clearDeskByUsr() async {
    try {
      final desk = await _getDeskByUser();

      if (desk != null) {
        await restClient.auth.delete('/attendantDeskAssignment/${desk.id}');
      }

      return Right(unit);
    } on DioException catch (e, s) {
      log('Erro ao deletar numero do guiche', error: e, stackTrace: s);
      return Left(RepositoryException());
    }
  }

  Future<({String id, int deskNumber})?> _getDeskByUser() async {
    final Response(:List data) = await restClient.auth.get(
        '/attendantDeskAssignment',
        queryParameters: {'user_id': '#userAuthRef'});

    if (data
        case List(
          isNotEmpty: true,
          first: {'id': String id, 'desk_number': int deskNumber}
        )) {
      return (
        id: id,
        deskNumber: deskNumber,
      );
    }
    return null;
  }

  @override
  Future<Either<RepositoryException, int>> getDeskAssignment() async {
    try {
      final Response(data: List(first: data)) = await restClient.auth.get(
          '/attendantDeskAssignment',
          queryParameters: {'user_id': '#userAuthRef'});
      return Right(data['desk_number']);
    } on DioException catch (e, s) {
      log('Erro ao buscar o número do guichê', error: e, stackTrace: s);
      return Left(RepositoryException());
    }
  }
}
