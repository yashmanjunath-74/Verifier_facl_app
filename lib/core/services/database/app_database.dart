import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:verifier_facl/core/models/attendance_record.dart';
import 'package:verifier_facl/core/models/class_group.dart';
import 'package:verifier_facl/core/models/faculty.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/services/database/daos/attendance_record_dao.dart';
import 'package:verifier_facl/core/services/database/daos/class_group_dao.dart';
import 'package:verifier_facl/core/services/database/daos/faculty_dao.dart';
import 'package:verifier_facl/core/services/database/daos/student_dao.dart';
import 'package:verifier_facl/core/utils/constants.dart';

part 'app_database.g.dart'; // the generated code will be there

// We now have two converters: one for nullable DateTime and one for non-nullable.
@TypeConverters([DateTimeConverter, NonNullableDateTimeConverter])
@Database(version: AppConstants.databaseVersion, entities: [Faculty, ClassGroup, Student, AttendanceRecord], )
abstract class AppDatabase extends FloorDatabase {
  FacultyDao get facultyDao;
  ClassGroupDao get classGroupDao;
  StudentDao get studentDao;
  AttendanceRecordDao get attendanceRecordDao;
}

/// Type converter for `DateTime?` which is stored as `int?` (milliseconds since epoch) in the database.
class DateTimeConverter extends TypeConverter<DateTime?, int?> {
  @override
  DateTime? decode(int? databaseValue) {
    if (databaseValue == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int? encode(DateTime? value) {
    if (value == null) {
      return null;
    }
    return value.millisecondsSinceEpoch;
  }
}

/// Type converter for non-nullable `DateTime` which is stored as `int` in the database.
class NonNullableDateTimeConverter extends TypeConverter<DateTime, int> {
  @override
  DateTime decode(int databaseValue) {
    return DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int encode(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}

