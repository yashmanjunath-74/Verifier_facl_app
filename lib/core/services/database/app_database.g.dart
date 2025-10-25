// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  FacultyDao? _facultyDaoInstance;

  ClassGroupDao? _classGroupDaoInstance;

  StudentDao? _studentDaoInstance;

  AttendanceRecordDao? _attendanceRecordDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Faculty` (`id` INTEGER, `faculty_id` TEXT NOT NULL, `username` TEXT NOT NULL, `password_hash` TEXT NOT NULL, `password_salt` TEXT NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ClassGroup` (`id` INTEGER, `class_id` TEXT NOT NULL, `class_name` TEXT NOT NULL, `course_code` TEXT NOT NULL, `faculty_id` TEXT NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Student` (`id` INTEGER, `student_id` TEXT NOT NULL, `name` TEXT NOT NULL, `class_id` TEXT NOT NULL, `public_key` TEXT NOT NULL, `enrolled_at` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `AttendanceRecord` (`id` INTEGER, `record_id` TEXT NOT NULL, `class_id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `session_id` TEXT NOT NULL, `date` INTEGER NOT NULL, `status` TEXT NOT NULL, `verified_at` INTEGER, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  FacultyDao get facultyDao {
    return _facultyDaoInstance ??= _$FacultyDao(database, changeListener);
  }

  @override
  ClassGroupDao get classGroupDao {
    return _classGroupDaoInstance ??= _$ClassGroupDao(database, changeListener);
  }

  @override
  StudentDao get studentDao {
    return _studentDaoInstance ??= _$StudentDao(database, changeListener);
  }

  @override
  AttendanceRecordDao get attendanceRecordDao {
    return _attendanceRecordDaoInstance ??=
        _$AttendanceRecordDao(database, changeListener);
  }
}

class _$FacultyDao extends FacultyDao {
  _$FacultyDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _facultyInsertionAdapter = InsertionAdapter(
            database,
            'Faculty',
            (Faculty item) => <String, Object?>{
                  'id': item.id,
                  'faculty_id': item.facultyId,
                  'username': item.username,
                  'password_hash': item.passwordHash,
                  'password_salt': item.passwordSalt,
                  'created_at':
                      _nonNullableDateTimeConverter.encode(item.createdAt)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Faculty> _facultyInsertionAdapter;

  @override
  Future<Faculty?> findFacultyByUsername(String username) async {
    return _queryAdapter.query('SELECT * FROM Faculty WHERE username = ?1',
        mapper: (Map<String, Object?> row) => Faculty(
            id: row['id'] as int?,
            facultyId: row['faculty_id'] as String,
            username: row['username'] as String,
            passwordHash: row['password_hash'] as String,
            passwordSalt: row['password_salt'] as String,
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [username]);
  }

  @override
  Future<Faculty?> findFirstFaculty() async {
    return _queryAdapter.query('SELECT * FROM Faculty LIMIT 1',
        mapper: (Map<String, Object?> row) => Faculty(
            id: row['id'] as int?,
            facultyId: row['faculty_id'] as String,
            username: row['username'] as String,
            passwordHash: row['password_hash'] as String,
            passwordSalt: row['password_salt'] as String,
            createdAt: _nonNullableDateTimeConverter
                .decode(row['created_at'] as int)));
  }

  @override
  Future<int?> getFacultyCount() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM Faculty',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> insertFaculty(Faculty faculty) async {
    await _facultyInsertionAdapter.insert(faculty, OnConflictStrategy.abort);
  }
}

class _$ClassGroupDao extends ClassGroupDao {
  _$ClassGroupDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _classGroupInsertionAdapter = InsertionAdapter(
            database,
            'ClassGroup',
            (ClassGroup item) => <String, Object?>{
                  'id': item.id,
                  'class_id': item.classId,
                  'class_name': item.className,
                  'course_code': item.courseCode,
                  'faculty_id': item.facultyId,
                  'created_at':
                      _nonNullableDateTimeConverter.encode(item.createdAt)
                },
            changeListener),
        _classGroupUpdateAdapter = UpdateAdapter(
            database,
            'ClassGroup',
            ['id'],
            (ClassGroup item) => <String, Object?>{
                  'id': item.id,
                  'class_id': item.classId,
                  'class_name': item.className,
                  'course_code': item.courseCode,
                  'faculty_id': item.facultyId,
                  'created_at':
                      _nonNullableDateTimeConverter.encode(item.createdAt)
                },
            changeListener),
        _classGroupDeletionAdapter = DeletionAdapter(
            database,
            'ClassGroup',
            ['id'],
            (ClassGroup item) => <String, Object?>{
                  'id': item.id,
                  'class_id': item.classId,
                  'class_name': item.className,
                  'course_code': item.courseCode,
                  'faculty_id': item.facultyId,
                  'created_at':
                      _nonNullableDateTimeConverter.encode(item.createdAt)
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ClassGroup> _classGroupInsertionAdapter;

  final UpdateAdapter<ClassGroup> _classGroupUpdateAdapter;

  final DeletionAdapter<ClassGroup> _classGroupDeletionAdapter;

  @override
  Stream<List<ClassGroup>> watchAllClassesByFacultyId(String facultyId) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM ClassGroup WHERE faculty_id = ?1 ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => ClassGroup(
            id: row['id'] as int?,
            classId: row['class_id'] as String,
            className: row['class_name'] as String,
            courseCode: row['course_code'] as String,
            facultyId: row['faculty_id'] as String,
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [facultyId],
        queryableName: 'ClassGroup',
        isView: false);
  }

  @override
  Future<ClassGroup?> findClassById(String classId) async {
    return _queryAdapter.query('SELECT * FROM ClassGroup WHERE class_id = ?1',
        mapper: (Map<String, Object?> row) => ClassGroup(
            id: row['id'] as int?,
            classId: row['class_id'] as String,
            className: row['class_name'] as String,
            courseCode: row['course_code'] as String,
            facultyId: row['faculty_id'] as String,
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [classId]);
  }

  @override
  Future<void> insertClass(ClassGroup classGroup) async {
    await _classGroupInsertionAdapter.insert(
        classGroup, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateClass(ClassGroup classGroup) async {
    await _classGroupUpdateAdapter.update(classGroup, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteClass(ClassGroup classGroup) async {
    await _classGroupDeletionAdapter.delete(classGroup);
  }
}

class _$StudentDao extends StudentDao {
  _$StudentDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _studentInsertionAdapter = InsertionAdapter(
            database,
            'Student',
            (Student item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'name': item.name,
                  'class_id': item.classId,
                  'public_key': item.publicKey,
                  'enrolled_at':
                      _nonNullableDateTimeConverter.encode(item.enrolledAt),
                  'created_at':
                      _nonNullableDateTimeConverter.encode(item.createdAt)
                },
            changeListener),
        _studentDeletionAdapter = DeletionAdapter(
            database,
            'Student',
            ['id'],
            (Student item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'name': item.name,
                  'class_id': item.classId,
                  'public_key': item.publicKey,
                  'enrolled_at':
                      _nonNullableDateTimeConverter.encode(item.enrolledAt),
                  'created_at':
                      _nonNullableDateTimeConverter.encode(item.createdAt)
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Student> _studentInsertionAdapter;

  final DeletionAdapter<Student> _studentDeletionAdapter;

  @override
  Stream<List<Student>> watchStudentsByClassId(String classId) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM Student WHERE class_id = ?1 ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => Student(
            id: row['id'] as int?,
            studentId: row['student_id'] as String,
            name: row['name'] as String,
            classId: row['class_id'] as String,
            publicKey: row['public_key'] as String,
            enrolledAt:
                _nonNullableDateTimeConverter.decode(row['enrolled_at'] as int),
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [classId],
        queryableName: 'Student',
        isView: false);
  }

  @override
  Future<List<Student>> findStudentsByClassId(String classId) async {
    return _queryAdapter.queryList('SELECT * FROM Student WHERE class_id = ?1',
        mapper: (Map<String, Object?> row) => Student(
            id: row['id'] as int?,
            studentId: row['student_id'] as String,
            name: row['name'] as String,
            classId: row['class_id'] as String,
            publicKey: row['public_key'] as String,
            enrolledAt:
                _nonNullableDateTimeConverter.decode(row['enrolled_at'] as int),
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [classId]);
  }

  @override
  Future<Student?> findStudentByStudentIdAndClassId(
    String studentId,
    String classId,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Student WHERE student_id = ?1 AND class_id = ?2',
        mapper: (Map<String, Object?> row) => Student(
            id: row['id'] as int?,
            studentId: row['student_id'] as String,
            name: row['name'] as String,
            classId: row['class_id'] as String,
            publicKey: row['public_key'] as String,
            enrolledAt:
                _nonNullableDateTimeConverter.decode(row['enrolled_at'] as int),
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [studentId, classId]);
  }

  @override
  Future<Student?> findByStudentId(String studentId) async {
    return _queryAdapter.query(
        'SELECT * FROM Student WHERE student_id = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => Student(
            id: row['id'] as int?,
            studentId: row['student_id'] as String,
            name: row['name'] as String,
            classId: row['class_id'] as String,
            publicKey: row['public_key'] as String,
            enrolledAt:
                _nonNullableDateTimeConverter.decode(row['enrolled_at'] as int),
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [studentId]);
  }

  @override
  Future<void> deleteStudentsByClassId(String classId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Student WHERE class_id = ?1',
        arguments: [classId]);
  }

  @override
  Future<void> insertStudent(Student student) async {
    await _studentInsertionAdapter.insert(student, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteStudent(Student student) async {
    await _studentDeletionAdapter.delete(student);
  }
}

class _$AttendanceRecordDao extends AttendanceRecordDao {
  _$AttendanceRecordDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _attendanceRecordInsertionAdapter = InsertionAdapter(
            database,
            'AttendanceRecord',
            (AttendanceRecord item) => <String, Object?>{
                  'id': item.id,
                  'record_id': item.recordId,
                  'class_id': item.classId,
                  'student_id': item.studentId,
                  'session_id': item.sessionId,
                  'date': _nonNullableDateTimeConverter.encode(item.date),
                  'status': item.status,
                  'verified_at': _dateTimeConverter.encode(item.verifiedAt),
                  'created_at':
                      _nonNullableDateTimeConverter.encode(item.createdAt)
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<AttendanceRecord> _attendanceRecordInsertionAdapter;

  @override
  Future<List<AttendanceRecord>> findPresentRecordsBySessionId(
      String sessionId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM AttendanceRecord WHERE session_id = ?1 AND status = \"present\"',
        mapper: (Map<String, Object?> row) => AttendanceRecord(id: row['id'] as int?, recordId: row['record_id'] as String, classId: row['class_id'] as String, studentId: row['student_id'] as String, sessionId: row['session_id'] as String, date: _nonNullableDateTimeConverter.decode(row['date'] as int), status: row['status'] as String, verifiedAt: _dateTimeConverter.decode(row['verified_at'] as int?), createdAt: _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [sessionId]);
  }

  @override
  Stream<List<AttendanceRecord>> watchSessionsByClassId(String classId) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM AttendanceRecord WHERE class_id = ?1 GROUP BY session_id ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => AttendanceRecord(
            id: row['id'] as int?,
            recordId: row['record_id'] as String,
            classId: row['class_id'] as String,
            studentId: row['student_id'] as String,
            sessionId: row['session_id'] as String,
            date: _nonNullableDateTimeConverter.decode(row['date'] as int),
            status: row['status'] as String,
            verifiedAt: _dateTimeConverter.decode(row['verified_at'] as int?),
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [classId],
        queryableName: 'AttendanceRecord',
        isView: false);
  }

  @override
  Future<List<AttendanceRecord>> findRecordsBySessionId(
      String sessionId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM AttendanceRecord WHERE session_id = ?1',
        mapper: (Map<String, Object?> row) => AttendanceRecord(
            id: row['id'] as int?,
            recordId: row['record_id'] as String,
            classId: row['class_id'] as String,
            studentId: row['student_id'] as String,
            sessionId: row['session_id'] as String,
            date: _nonNullableDateTimeConverter.decode(row['date'] as int),
            status: row['status'] as String,
            verifiedAt: _dateTimeConverter.decode(row['verified_at'] as int?),
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [sessionId]);
  }

  @override
  Stream<List<AttendanceRecord>> watchRecordsBySessionId(String sessionId) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM AttendanceRecord WHERE session_id = ?1 ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => AttendanceRecord(
            id: row['id'] as int?,
            recordId: row['record_id'] as String,
            classId: row['class_id'] as String,
            studentId: row['student_id'] as String,
            sessionId: row['session_id'] as String,
            date: _nonNullableDateTimeConverter.decode(row['date'] as int),
            status: row['status'] as String,
            verifiedAt: _dateTimeConverter.decode(row['verified_at'] as int?),
            createdAt:
                _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [sessionId],
        queryableName: 'AttendanceRecord',
        isView: false);
  }

  @override
  Future<AttendanceRecord?> findRecordForStudentInSession(
    String studentId,
    String sessionId,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM AttendanceRecord WHERE student_id = ?1 AND session_id = ?2 LIMIT 1',
        mapper: (Map<String, Object?> row) => AttendanceRecord(id: row['id'] as int?, recordId: row['record_id'] as String, classId: row['class_id'] as String, studentId: row['student_id'] as String, sessionId: row['session_id'] as String, date: _nonNullableDateTimeConverter.decode(row['date'] as int), status: row['status'] as String, verifiedAt: _dateTimeConverter.decode(row['verified_at'] as int?), createdAt: _nonNullableDateTimeConverter.decode(row['created_at'] as int)),
        arguments: [studentId, sessionId]);
  }

  @override
  Future<void> insertAttendanceRecord(AttendanceRecord record) async {
    await _attendanceRecordInsertionAdapter.insert(
        record, OnConflictStrategy.replace);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
final _nonNullableDateTimeConverter = NonNullableDateTimeConverter();
