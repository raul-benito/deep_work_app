import 'dart:async';

import 'package:sqflite/sqflite.dart';

/// Instance of a ritual completion.
class RitualComplete {
  int id;
  int ritualId;
  DateTime completionTime;

  static final String table = "ritualsComplete";
  static final String columnId = "_id";
  static final String columnRitual = "ritualId";
  static final String columnDone = "timeStamp";

  static String getTableCreation() {
    return '''create table $table (
       $columnId integer primary key autoincrement, 
       $columnRitual integer not null,
       $columnDone integer DEFAULT CURRENT_TIMESTAMP,
       FOREIGN KEY($columnRitual) REFERENCES rituals(_id))
    ''';
  }

  static Future<RitualComplete> insert(int ritualId, Database db) async {
    RitualComplete ritualComplete = new RitualComplete();
    ritualComplete.id = await db.insert(table, {columnRitual: ritualId});
    ritualComplete.ritualId = ritualId;
    var value =
        await _getById(ritualComplete.id, db).then((map) => map[columnDone]);
    ritualComplete.completionTime = DateTime.tryParse(value);
    return ritualComplete;
  }

  static Future<RitualComplete> get(int completionId, Database db) async {
    Map map = await _getById(completionId, db);
    if (map != null) {
      RitualComplete ritualComplete = new RitualComplete();
      ritualComplete.completionTime = DateTime.parse(map[columnDone]);
      ritualComplete.id = map[columnId];
      ritualComplete.ritualId = map[columnRitual];
      return ritualComplete;
    }
    return Future.error("No completion by that id.");
  }

  static Future<List<RitualComplete>> getByDateRangeAndRitualId(
      int ritualId, DateTime from, DateTime to, Database db) async {
    final results = List<RitualComplete>();
    List<Map> maps = await db.query(table,
        columns: [columnId, columnDone, columnRitual],
        where:
            '$columnRitual = ? and $columnDone BETWEEN date(?) AND date(?,+"1 day")',
        whereArgs: [ritualId, from.toIso8601String(), to.toIso8601String()]);
    maps.forEach((map) {
      RitualComplete ritualComplete = new RitualComplete();
      ritualComplete.completionTime = DateTime.parse(map[columnDone]);
      ritualComplete.id = map[columnId];
      ritualComplete.ritualId = map[columnRitual];
      results.add(ritualComplete);
    });
    return results;
  }

  static Future<ComplitionStats> getLongestSteak(
      int ritualId, Database db) async {
    final filterBySingleDate =
        "(select distinct(date($columnDone)) as $columnDone from $table where $columnRitual=$ritualId)";
    List<Map<String, dynamic>> maps = await db.rawQuery("""
        select max(date($columnDone)) as $columnDone, count(*) as streak
        from (select t1.$columnDone as $columnDone ,
              date(t1.$columnDone,
                   -(select count(*) from $filterBySingleDate 
                     t2 where date(t2.$columnDone)<=date(t1.$columnDone)) ||' day') as grp
    from $filterBySingleDate t1 ) group by grp order by streak DESC""");
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map todayValue;
    try {
      todayValue =
          maps.singleWhere((f) => DateTime.parse(f[columnDone]) == today);
    } catch (e) {
      final yesterday = today.subtract(Duration(days: 1));
      todayValue = maps.singleWhere(
          (f) => DateTime.parse(f[columnDone]) == yesterday,
          orElse: () => {"streak": 0});
    }
    return ComplitionStats()
      ..ritualId = ritualId
      ..maxStride = maps.isEmpty ? 0 : maps.first["streak"]
      ..currentStride = todayValue["streak"];
  }

  // Private parts.
  static Future<Map> _getById(int id, Database db) async {
    List<Map> maps = await db.query(table,
        columns: [columnId, columnDone, columnRitual],
        where: "$columnId = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return maps.first;
    }
    return null;
  }
}

class RitualStep {
  int id;
  int ritualId;
  String title;
  String description;

  static final String table = "ritualSteps";
  static final String columnId = "_id";
  static final String columnRitualId = "ritualId";
  static final String columnTitle = "title";
  static final String columnDescription = "description";
  static final String columnOrder = "stepOrder";

  static String getTableCreation() {
    return '''create table $table (
       $columnId integer primary key autoincrement, 
       $columnRitualId integer,
       $columnTitle string,
       $columnDescription string,
       $columnOrder integer,
       FOREIGN KEY($columnRitualId) REFERENCES rituals(_id))      
    ''';
  }

  static Future<RitualStep> insert(
      String title, String description, int ritualId, Database db) async {
    RitualStep step = new RitualStep();
    final result = await db.query(table,
        columns: ["MAX($columnOrder)"],
        where: "$columnRitualId = ?",
        whereArgs: [ritualId]);
    var order = 1;
    if (result.first["MAX($columnOrder)"] != null) {
      order = result.first["MAX($columnOrder)"] + 1;
    }
    step.id = await db.insert(table, {
      columnTitle: title,
      columnDescription: description,
      columnRitualId: ritualId,
      columnOrder: order,
    });
    return get(step.id, db);
  }

  Future updateOrder(int newOrder, Database db) async {
    return db.update(table, {columnOrder: newOrder},
        where: "$columnId = ?", whereArgs: [id]);
  }

  static Future<RitualStep> get(int stepId, Database db) async {
    Map map = await _getById(stepId, db);
    if (map != null) {
      return fromMap(map);
    }
    return Future.error("No step by that id.");
  }

  static RitualStep fromMap(Map map) {
    RitualStep step = new RitualStep();
    step.id = map[columnId];
    step.title = map[columnTitle];
    step.description = map[columnDescription];
    step.ritualId = map[columnRitualId];
    return step;
  }

  static Future<List<RitualStep>> getByRitualId(
      int ritualId, Database db) async {
    List<RitualStep> result = new List<RitualStep>();
    var maps = await db.query(table,
        columns: [
          columnId,
          columnTitle,
          columnDescription,
          columnRitualId,
          columnOrder
        ],
        where: "$columnRitualId = ?",
        whereArgs: [ritualId],
        orderBy: columnOrder);
    maps.forEach((map) {
      result.add(fromMap(map));
    });
    return result;
  }

  // Private parts.
  static Future<Map> _getById(int id, Database db) async {
    List<Map> maps = await db.query(table,
        columns: [columnId, columnTitle, columnDescription, columnRitualId],
        where: "$columnId = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return maps.first;
    }
    return null;
  }
}

class ComplitionStats {
  int ritualId;
  double ratio = 0;
  int maxStride = 0;
  int currentStride = 0;
  String description;
}

class Ritual {
  int id;
  String title;
  DateTime creationTime;

  Database _db;

  Future<RitualStep> insertStep(String title, String description) {
    return RitualStep.insert(title, description, id, _db);
  }

  static final String table = "rituals";
  static final String columnId = "_id";
  static final String columnTitle = "description";
  static final String columnCreation = "timeStamp";

  static String getTableCreation() {
    return '''create table $table (
       $columnId integer primary key autoincrement, 
       $columnTitle string,
       $columnCreation integer DEFAULT CURRENT_TIMESTAMP)
    ''';
  }

  static Future<Ritual> insert(String title, Database db) async {
    final id = await db.insert(table, {columnTitle: title});
    return get(id, db);
  }

  static Future<List<Ritual>> getAvilableRituals(Database db) async {
    List<Map> maps =
        await db.query(table, columns: [columnId, columnTitle, columnCreation]);
    return maps.map((map) => fromMap(db, map)).toList();
  }

  static Future<Ritual> get(int ritualId, Database db) async {
    Map map = await _getById(ritualId, db);
    if (map != null) {
      return fromMap(db, map);
    }
    return Future.error("No ritual by that id.");
  }

  static Ritual fromMap(Database db, Map map) {
    Ritual ritual = new Ritual();
    ritual._db = db;
    ritual.creationTime = DateTime.parse(map[columnCreation]);
    ritual.id = map[columnId];
    ritual.title = map[columnTitle];
    return ritual;
  }

  // Private parts.
  static Future<Map> _getById(int id, Database db) async {
    List<Map> maps = await db.query(table,
        columns: [columnId, columnTitle, columnCreation],
        where: "$columnId = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return maps.first;
    }
    return null;
  }

  Future<List<RitualStep>> getRitualSteps() async {
    return RitualStep.getByRitualId(id, _db);
  }

  Future updateRitualStepOrder(List<RitualStep> newOrder) async {
    int i = 0;
    newOrder.forEach((f) async => await f.updateOrder(i++, _db));
  }

  Future<List<DateTime>> getComplitions(DateTime arround) async {
    try {
      final instances = await RitualComplete.getByDateRangeAndRitualId(
          id, arround.subtract(Duration(days: 32)), arround, _db);
      return instances.map((f) => f.completionTime).toList();
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  void markCompletion() {
    RitualComplete.insert(id, _db);
  }

  Future<ComplitionStats> getComplitionStats() async {
    try {
      final stats = await RitualComplete.getLongestSteak(id, _db);
      if (stats.maxStride < 40) stats.maxStride = 40;
      stats.description = "${stats.currentStride} / ${stats.maxStride}";
      stats.ratio = stats.currentStride / stats.maxStride;
      return stats;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<bool> isCompletedForNow() async {
    final now = DateTime.now();
    final completion = await RitualComplete.getByDateRangeAndRitualId(
        id, DateTime(now.year, now.month, now.day), now, _db);
    return completion.isNotEmpty;
  }
}

class RitualsProvider {
  Future<Database> db;

  RitualsProvider(path) {
    open(path);
  }

  Future<Database> open(String path) async {
    db = new Future(() {
      final dbInitial = openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("Creating tables");
        await db.execute(Ritual.getTableCreation());
        await db.execute(RitualComplete.getTableCreation());
        await db.execute(RitualStep.getTableCreation());
      });
      // Assure there is a ritual 0
      return dbInitial.then((dbReady) async {
        Ritual ritual;
        ritual = await Ritual.get(1, dbReady).catchError((e) async {
          print("Creating evening ritual. $e");
          ritual = await Ritual.insert("Evening ritual", dbReady);
          await ritual.insertStep(
              "Check emails", "You don't want to forget something.");
          await ritual.insertStep(
              "Say the magic words", "Paolov dog you know.");
          // TEST
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-12-20"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-12-21"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-12-22"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-12-24"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-12-25"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-12-30"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-12-31"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-10-20"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-11-01"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-11-02"});
          dbReady.insert(
              "ritualsComplete", {"ritualId": 1, "timeStamp": "2018-09-03"});
          print("ddddd1");
        });
        return dbInitial;
      });
    });
  }

  Future<Ritual> createRitual(String title) {
    return db.then((dbReady) => Ritual.insert(title, dbReady));
  }

  Future<Ritual> getRitual(int ritualId) async {
    return db.then((dbReady) => Ritual.get(ritualId, dbReady));
  }

  Future<List<Ritual>> getRituals() async {
    return db.then((dbReady) async {
      return Ritual.getAvilableRituals(dbReady);
    });
  }

  Future close() async => db.then((dbReady) => dbReady.close());
}
