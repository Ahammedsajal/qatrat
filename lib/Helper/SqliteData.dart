import 'dart:async';
import 'dart:io';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/ui/styles/DesignConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;
  final String CART_TABLE = 'tblcart';
  final String SAVEFORLATER_TABLE = 'tblsaveforlater';
  final String FAVORITE_TABLE = 'tblfavorite';
  final String MOSTLIKE_TABLE = 'tblmostlike';
  final String MOSTFAV_TABLE = 'tblmostfav';
  final String PID = 'PID';
  final String VID = 'VID';
  final String QTY = 'QTY';
  final String TYPE = 'TYPE';
  static Database? _db;
  DatabaseHelper.internal();
  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "customer.db");
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      final ByteData data = await rootBundle.load(join("assets", "customer.db"));
      final List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    } else {}
    final db = await openDatabase(path);
    return db;
  }

  Future<bool?> getFavById(String pid) async {
    bool count = false;
    final db1 = await db;
    final result = await db1!
        .rawQuery("SELECT * FROM $FAVORITE_TABLE WHERE $PID = ?", [pid]);
    if (result.isNotEmpty) {
      count = true;
    }
    return count;
  }

  addAndRemoveFav(String pid, bool isAdd) async {
    final db1 = await db;
    if (isAdd) {
      addFavorite(pid);
    } else {
      db1!.rawQuery("DELETE FROM $FAVORITE_TABLE WHERE $PID = $pid");
      getFav();
    }
  }

  addFavorite(String pid) async {
    final db1 = await db;
    final Map<String, dynamic> row = {
      DatabaseHelper._instance.PID: pid,
    };
    db1!.insert(FAVORITE_TABLE, row);
  }

  addMostFav(String pid) async {
    final db1 = await db;
    final Map<String, dynamic> row = {
      DatabaseHelper._instance.PID: pid,
    };
    final List<Map> result = await db1!.query(DatabaseHelper._instance.MOSTFAV_TABLE);
    if (result.length >= 10) {
      final bool? check = await checkMostFavExists(pid);
      if (!check!) {
        db1.rawQuery("DELETE FROM $MOSTFAV_TABLE WHERE $PID = ?",
            [result[result.length - 1][PID]],).then((value) async {
          db1.insert(MOSTFAV_TABLE, row);
        });
      }
    } else {
      final bool? check = await checkMostFavExists(pid);
      if (!check!) {
        db1.insert(MOSTFAV_TABLE, row);
      }
    }
  }

  addMostLike(String pid) async {
    final db1 = await db;
    final Map<String, dynamic> row = {
      DatabaseHelper._instance.PID: pid,
    };
    final List<Map> result =
        await db1!.query(DatabaseHelper._instance.MOSTLIKE_TABLE);
    if (result.length >= 10) {
      final bool? check = await checkMostLikeExists(pid);
      if (!check!) {
        db1.rawQuery("DELETE FROM $MOSTLIKE_TABLE WHERE $PID = ?",
            [result[result.length - 1][PID]],).then((value) async {
          db1.insert(MOSTLIKE_TABLE, row);
        });
      }
    } else {
      final bool? check = await checkMostLikeExists(pid);
      if (!check!) {
        db1.insert(MOSTLIKE_TABLE, row);
      }
    }
  }

  checkSaveForLaterExistsRemove(String pid, String vid) async {
    final db1 = await db;
    final result = await db1!.rawQuery(
        'SELECT * FROM $SAVEFORLATER_TABLE WHERE $VID = ? AND $PID = ?',
        [vid, pid],);
    if (result.isNotEmpty) {
      removeSaveForLater(vid, pid);
    }
  }

  Future<bool?> checkMostFavExists(String pid) async {
    final db1 = await db;
    final result = await db1!
        .rawQuery("SELECT * FROM $MOSTFAV_TABLE WHERE $PID = ?", [pid]);
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool?> checkMostLikeExists(String pid) async {
    final db1 = await db;
    final result = await db1!
        .rawQuery("SELECT * FROM $MOSTLIKE_TABLE WHERE $PID = ?", [pid]);
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<String>?> getMostFav() async {
    final List<String> ids = [];
    final db1 = await db;
    final List<Map> result = await db1!.query(DatabaseHelper._instance.MOSTFAV_TABLE);
    for (final row in result) {
      ids.add(row[PID]);
    }
    return ids;
  }

  Future<List<String>?> getMostLike() async {
    final List<String> ids = [];
    final db1 = await db;
    final List<Map> result =
        await db1!.query(DatabaseHelper._instance.MOSTLIKE_TABLE);
    for (final row in result) {
      ids.add(row[PID]);
    }
    return ids;
  }

  Future<List<Map>> getOffFav() async {
    final db1 = await db;
    final List<Map> result =
        await db1!.query(DatabaseHelper._instance.FAVORITE_TABLE);
    return result;
  }

  Future<List<String>?> getFav() async {
    final List<String> ids = [];
    final db1 = await db;
    final List<Map> result =
        await db1!.query(DatabaseHelper._instance.FAVORITE_TABLE);
    for (final row in result) {
      ids.add(row[PID]);
    }
    return ids;
  }

  clearFav() async {
    final db1 = await db;
    db1!.execute("DELETE FROM $FAVORITE_TABLE");
  }

  Future<bool> insertCart(String pid, String vid, String qty, String type,
      BuildContext context,) async {
    final dbClient = await db;
    String? getType;
    String? check;
    check = await checkCartItemExists(pid, vid);
    checkSaveForLaterExistsRemove(pid, vid);
    if (check != "0") {
      updateCart(pid, vid, qty);
      return true;
    } else {
      getType = await checkCartItemTypeExists(pid, vid);
      print("getType111***$getType****$type");
      if (getType != "digital_product" || getType == "0") {
        final String query =
            "INSERT INTO $CART_TABLE ($PID,$VID,$QTY,$TYPE) SELECT '$pid','$vid','$qty','$type' WHERE NOT EXISTS(SELECT $PID,$VID FROM $CART_TABLE WHERE $PID = '$pid' AND $VID='$VID')";
        dbClient!.execute(query);
        await getTotalCartCount(context);
        return true;
      } else {
        setSnackbar(
            "you can only add either digital product or physical product to cart",
            context,);
        return false;
      }
    }
  }

  updateCart(String pid, String vid, String qty) async {
    final db1 = await db;
    final Map<String, dynamic> row = {
      DatabaseHelper._instance.QTY: qty,
    };
    db1!.update(CART_TABLE, row,
        where: "$VID = ? AND $PID = ?", whereArgs: [vid, pid],);
  }

  removeCart(String vid, String pid, BuildContext context) async {
    final db1 = await db;
    db1!.rawQuery(
        "DELETE FROM $CART_TABLE WHERE $VID = ? AND $PID = ?", [vid, pid],);
    await getTotalCartCount(context);
  }

  clearCart() async {
    final db1 = await db;
    db1!.execute("DELETE FROM $CART_TABLE");
  }

  Future<String?> checkCartItemExists(String pid, String vid) async {
    final db1 = await db;
    final result = await db1!.rawQuery(
        "SELECT * FROM $CART_TABLE WHERE $VID = ? AND $PID = ?", [vid, pid],);
    if (result.isNotEmpty) {
      return result[0][QTY].toString();
    } else {
      return "0";
    }
  }

  Future<String?> checkCartItemTypeExists(String pid, String vid) async {
    final db1 = await db;
    final result = await db1!.rawQuery("SELECT * FROM $CART_TABLE");
    if (result.isNotEmpty) {
      return result[0][TYPE].toString();
    } else if (result.isEmpty) {
      return "0";
    } else {
      return "";
    }
  }

  Future<List<String>?> getCart() async {
    final List<String> ids = [];
    final db1 = await db;
    final List<Map> result = await db1!.query(DatabaseHelper._instance.CART_TABLE);
    for (final row in result) {
      ids.add(row[VID]);
    }
    return ids;
  }

  Future<int> getTotalCartCount(BuildContext context) async {
    final db1 = await db;
    final List<Map> result = await db1!.query(DatabaseHelper._instance.CART_TABLE);
    context.read<UserProvider>().setCartCount(result.length.toString());
    return result.length;
  }

  Future<List<Map>> getOffCart() async {
    final db1 = await db;
    final List<Map> result = await db1!.query(DatabaseHelper._instance.CART_TABLE);
    return result;
  }

  Future<List<Map>> getOffSaveLater() async {
    final db1 = await db;
    final List<Map> result =
        await db1!.query(DatabaseHelper._instance.SAVEFORLATER_TABLE);
    return result;
  }

  Future<List<String>?> getSaveForLater() async {
    final List<String> ids = [];
    final db1 = await db;
    final List<Map> result =
        await db1!.query(DatabaseHelper._instance.SAVEFORLATER_TABLE);
    for (final row in result) {
      ids.add(row[VID]);
    }
    return ids;
  }

  addToSaveForLater(String pid, String vid, String qty) async {
    final dbClient = await db;
    final String query =
        "INSERT INTO $SAVEFORLATER_TABLE ($PID,$VID,$QTY) SELECT '$pid','$vid','$qty' WHERE NOT EXISTS(SELECT $PID,$VID FROM $CART_TABLE WHERE $PID = '$pid' AND $VID='$VID')";
    dbClient!.execute(query);
  }

  Future<String?> checkSaveForLaterExists(String pid, String vid) async {
    final db1 = await db;
    final result = await db1!.rawQuery(
        "SELECT * FROM $SAVEFORLATER_TABLE WHERE $VID = ? AND $PID = ?",
        [vid, pid],);
    if (result.isNotEmpty) {
      return result[0][QTY].toString();
    } else {
      return "0";
    }
  }

  moveToCartOrSaveLater(String from, String vid, String pid, String type,
      BuildContext context,) async {
    String? qty = "";
    String? getType;
    if (from == "cart") {
      qty = await checkCartItemExists(pid, vid);
      addToSaveForLater(pid, vid, qty!);
      await removeCart(vid, pid, context);
    } else {
      getType = await checkCartItemTypeExists(pid, vid);
      print("getType***$getType****$type");
      if (getType == type || getType == "0") {
        qty = await checkSaveForLaterExists(pid, vid);
        insertCart(pid, vid, qty!, type, context);
        await removeSaveForLater(vid, pid);
      } else {
        setSnackbar(
            "you can only add either digital product or physical product to cart",
            context,);
      }
    }
  }

  removeSaveForLater(String vid, String pid) async {
    final db1 = await db;
    db1!.rawQuery("DELETE FROM $SAVEFORLATER_TABLE WHERE $VID = ? AND $PID = ?",
        [vid, pid],);
  }

  clearSaveForLater() async {
    final db1 = await db;
    db1!.execute("DELETE FROM $SAVEFORLATER_TABLE");
  }

  Future close() async {
    final dbClient = await db;
    return dbClient!.close();
  }
}
