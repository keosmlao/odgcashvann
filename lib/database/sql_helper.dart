import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE Inventory(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code  TEXT ,
        item_name TEXT ,
        unitCost TEXT,
        barcode TEXT,
        groupMain TEXT,
        mainName TEXT,
        groupSub TEXT,
        subName TEXT,
        group_sub2 TEXT,
        sub_name_2 TEXT,
        itemBrand TEXT,
        average_cost TEXT,
        item_pattern TEXT,
        pattern_name TEXT,
        cat_name TEXT,
        item_category TEXT
      )""");
    await database.execute("""CREATE TABLE Vanstock(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code  TEXT ,
        item_name TEXT ,
        unit_code TEXT,
        barcode TEXT,
        balance_qty REAL,
        average_cost TEXT
      )""");
    await database.execute("""CREATE TABLE Rproduct(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code  TEXT ,
        item_name TEXT ,
        barcode TEXT,
        unit_code TEXT,
        qty REAL
      )""");
    await database.execute("""CREATE TABLE tb_order(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code  TEXT ,
        item_name TEXT ,
        barcode TEXT,
        unit_code TEXT,
        qty REAL,
        price REAL,
        average_cost TEXT,
        cust_code TEXT,
        discount REAL,
        price_2 REAL,
        sum_amount REAL)""");
    // sale Order
    await database.execute("""CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code TEXT ,
        barcode TEXT,
        item_name TEXT,
        qty REAL,
        unit_code TEXT,
        cust_code TEXT,
        price TEXT,
        discount TEXT,
        sum_amount TEXT,
        average_cost TEXT,
        discount_amount TEXT,
        product_type TEXT,
        item_main_code TEXT,
        discount_type TEXT)""");
    // sale Order
    await database.execute("""CREATE TABLE draft_promotion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code TEXT,
        item_name TEXT,
        qty REAL,
        for_qty REAL,
        unit_code TEXT,
        average_cost TEXT,
        item_main_code TEXT)""");
    // sale Order
    await database.execute("""CREATE TABLE customer(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cust_code TEXT,
        cust_name TEXT,
        area_code TEXT,
        logistic_area TEXT,
        latlng TEXT)""");

    // count Stock
    await database.execute("""CREATE TABLE countstock(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code TEXT,
        item_name TEXT,
        balance_qty REAL,
        count_qty REAL,
        unit_code TEXT,
        sale_code TEXT)""");
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'cashvan11.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  // Create new item (LisProductAll)
  static Future<int> createInven(
      String item_code,
      String item_name,
      String unitCost,
      String barcode,
      String groupMain,
      String mainName,
      String groupSub,
      String subName,
      String groupSub2,
      String subName_2,
      String itemBrand,
      String average_cost,
      String item_pattern,
      String pattern_name,
      String cat_name,
      String item_category) async {
    final db = await SQLHelper.db();

    final data = {
      'item_code': item_code,
      'item_name': item_name,
      'unitCost': unitCost,
      'barcode': barcode,
      'groupMain': groupMain,
      'mainName': mainName,
      'groupSub': groupSub,
      'subName': subName,
      'group_sub2': groupSub2,
      'sub_name_2': subName_2,
      'itemBrand': itemBrand,
      'average_cost': average_cost,
      'item_pattern': item_pattern,
      'pattern_name': pattern_name,
      'cat_name': cat_name,
      'item_category': item_category
    };
    final id = await db.insert('Inventory', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Delete
  static Future<void> deleteAll() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("Inventory");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Update an item by id
  static Future<int> UpdateBarcode(String code, String barcode) async {
    print(code + barcode);
    final db = await SQLHelper.db();

    final data = {
      'barcode': barcode,
    };
    final result = await db
        .update('Inventory', data, where: "code = ?", whereArgs: [code]);
    return result;
  }

// Stock Balance
  static Future<int> createVanstock(String item_code, String item_name,
      String unit_cost, String barcode, String qty) async {
    final db = await SQLHelper.db();
    final data = {
      'item_code': item_code,
      'item_name': item_name,
      'unitCost': unit_cost,
      'barcode': barcode,
      'qty': qty
    };
    final id = await db.insert('Vanstock', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getVanstock() async {
    final db = await SQLHelper.db();
    return db.query('Vanstock', orderBy: "item_code");
  }

  // Stock Balance
  static Future<int> addtodraftRp(String item_code, String item_name,
      String unit_code, String barcode, String qty) async {
    final db = await SQLHelper.db();
    final data = {
      'item_code': item_code,
      'item_name': item_name,
      'unit_code': unit_code,
      'barcode': barcode,
      'qty': qty
    };
    final id = await db.insert('Rproduct', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getDratRpstock() async {
    final db = await SQLHelper.db();
    return db.query('Rproduct', orderBy: "item_code");
  }

// ฟังก์ชันสำหรับลบข้อมูลโดยใช้ ID
  static Future<void> deleteRegestItem(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("Rproduct", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Delete
  static Future<void> deleteRespro() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("Rproduct");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // create sale order
  static Future<int> createOrder(
      String itemCode,
      String barcode,
      String itemName,
      String qty,
      String unitCode,
      String custCode,
      String price,
      String discount,
      String sumAmount,
      String averageCost,
      String discountAmount,
      String ProductType,
      String itemMainCode,
      String discountType) async {
    final db = await SQLHelper.db();

    final data = {
      'item_code': itemCode,
      'barcode': barcode,
      'item_name': itemName,
      'qty': qty,
      'unit_code': unitCode,
      'cust_code': custCode,
      'price': price,
      'discount': discount,
      'sum_amount': sumAmount,
      'average_cost': averageCost,
      "discount_amount": discountAmount,
      "product_type": ProductType,
      "item_main_code": itemMainCode,
      "discount_type": discountType
    };
    final id = await db.insert('orders', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getOrder() async {
    final db = await SQLHelper.db();
    return db.query('orders', orderBy: "id");
  }

  static Future<void> deleteItemOrder(String itemCode) async {
    final db = await SQLHelper.db();
    try {
      await db
          .delete("orders", where: "item_main_code = ?", whereArgs: [itemCode]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getOrders(
      String itemCode, custCode) async {
    final db = await SQLHelper.db();
    return db.query('orders',
        where: "item_code = ? and cust_code=?",
        whereArgs: [itemCode, custCode],
        limit: 1);
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getOrdersbtcust(
      String custCode) async {
    final db = await SQLHelper.db();
    return db.query('orders', where: "cust_code = ?", whereArgs: [custCode]);
  }

  // Delete
  static Future<void> deleteAlloder() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("orders");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  static Future<void> deleteItemFree(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("draft_promotion", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Draft order
  // create sale order
  static Future<int> createDraftpromotion(
      String itemCode,
      String itemName,
      String qty,
      String forQty,
      String unitCode,
      String averageCost,
      itemMainCode) async {
    final db = await SQLHelper.db();

    final data = {
      'item_code': itemCode,
      'item_name': itemName,
      'qty': qty,
      'for_qty': forQty,
      'unit_code': unitCode,
      "average_cost": averageCost,
      "item_main_code": itemMainCode
    };
    final id = await db.insert('draft_promotion', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getDraftPromotion() async {
    final db = await SQLHelper.db();
    return db.query('draft_promotion', orderBy: "id");
  }

  // Delete
  static Future<void> deleteDraftPro() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("draft_promotion");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  //
  // create sale order
  static Future<int> creatCustomer(String cust_code, String cust_name,
      String area_code, String logistic_area, String latlng) async {
    final db = await SQLHelper.db();

    final data = {
      'cust_code': cust_code,
      'cust_name': cust_name,
      'area_code': area_code,
      'logistic_area': logistic_area,
      'latlng': latlng,
    };
    final id = await db.insert('customer', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> Allcustomer() async {
    final db = await SQLHelper.db();
    return db.query('customer', orderBy: "id");
  }

  // Delete
  static Future<void> deleteallcustomer() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("customer");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Delete
  static Future<void> deleteacustomerbyid(id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("customer", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // create sale Count Stock
  static Future<int> createCountstock(
      String itemCode,
      String itemName,
      String balance_qty,
      String count_qty,
      String unit_code,
      String sale_code) async {
    final db = await SQLHelper.db();

    final data = {
      'item_code': itemCode,
      'item_name': itemName,
      'balance_qty': balance_qty,
      'count_qty': count_qty,
      'unit_code': unit_code,
      "sale_code": sale_code,
    };
    final id = await db.insert('countstock', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getDraftProductcount() async {
    final db = await SQLHelper.db();
    return db.query('countstock', orderBy: "id");
  }

  static Future<void> deleteItemcountbyid(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("countstock", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Delete
  static Future<void> deleteallitem_count() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("countstock");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  static Future<List<Map<String, dynamic>>> getGroupmain() async {
    final db = await SQLHelper.db();
    return db.rawQuery(
      'select  count(item_code) as count,groupMain,mainName from Inventory  group by groupMain,mainName ',
    );
  }

  static Future<List<Map<String, dynamic>>> getGroupsub(String id) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        'select  count(item_code) as count,groupSub,subName from Inventory  where  groupMain=? group by groupSub,subName ',
        [id]);
  }

  static Future<List<Map<String, dynamic>>> getGroupsub_2(
      String id, String id1) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        'select  count(item_code) as count,group_sub2,sub_name_2 from Inventory  where  groupMain=? and groupSub=? group by group_sub2,sub_name_2 ',
        [id, id1]);
  }

  static Future<List<Map<String, dynamic>>> getCAT(
      String id, String gs1, String gs2) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        'select  count(item_code) as count,item_category,cat_name from Inventory  where  groupMain=? and groupSub=? and group_sub2=? group by group_sub2,sub_name_2 ',
        [id, gs1, gs2]);
  }

  static Future<List<Map<String, dynamic>>> getPettern(
      String id, String gs, String gs2, String cat) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        'select  count(item_code) as count,item_pattern,pattern_name from Inventory  where  groupMain=? and groupSub=? and group_sub2=? and item_category=? group by item_pattern,pattern_name ',
        [id, gs, gs2, cat]);
  }

  static Future<List<Map<String, dynamic>>> getBrand(
      String id, String gs, String gs2, String cat, String pt) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        'select  count(item_code) as count,itemBrand from Inventory  where  groupMain=? and groupSub=? and group_sub2=? and item_category=? and item_pattern=? group by itemBrand ',
        [id, gs, gs2, cat, pt]);
  }

  static Future<List<Map<String, dynamic>>> getAllproduct() async {
    final db = await SQLHelper.db();
    return db.query('Inventory', orderBy: "item_code");
  }

  //ดึงข้อมูลแบบหลาย  Row
  static Future<List<Map<String, dynamic>>> queryByRow(String id) async {
    final db = await SQLHelper.db();
    return await db.query('Inventory',
        where: "code like ? or name1 like ? or barcode like ?",
        whereArgs: ['%$id%', '%$id%', '%$id%']);
  }

  static Future<List<Map<String, dynamic>>> getAllprobygm(String gm) async {
    final db = await SQLHelper.db();
    return db.rawQuery('select  * from Inventory  where  groupMain=?', [gm]);
  }

  static Future<List<Map<String, dynamic>>> getAllprobygmgs(
      String gm, String gs) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        'select  * from Inventory  where  groupMain=? and groupSub=?',
        [gm, gs]);
  }

  static Future<List<Map<String, dynamic>>> getAllprobygmgsgs2(
      String gm, String gs, String gs2) async {
    final db = await SQLHelper.db();
    print(gs2);
    return db.rawQuery(
        'select  * from Inventory  where  groupMain=? and groupSub=? and group_sub2=?',
        [gm, gs, gs2]);
  }

  static Future<List<Map<String, dynamic>>> getAllprobygmgsgs2cat(
      String gm, String gs, String gs2, String cat) async {
    final db = await SQLHelper.db();
    print(gs2);
    return db.rawQuery(
        'select  * from Inventory  where  groupMain=? and groupSub=? and group_sub2=? and item_category=?',
        [gm, gs, gs2, cat]);
  }

  static Future<List<Map<String, dynamic>>> getAllprobygmgsgs2catpettern(
      String gm, String gs, String gs2, String cat, String pettern) async {
    final db = await SQLHelper.db();
    print(gs2);
    return db.rawQuery(
        'select  * from Inventory  where  groupMain=? and groupSub=? and group_sub2=? and item_category=? and item_pattern=?',
        [gm, gs, gs2, cat, pettern]);
  }

  static Future<List<Map<String, dynamic>>> getAllprobygmgsgs2catpetternb(
      String gm,
      String gs,
      String gs2,
      String cat,
      String pettern,
      String brand) async {
    final db = await SQLHelper.db();
    return db.rawQuery(
        'select  * from Inventory  where  groupMain=? and groupSub=? and group_sub2=? and item_category=? and item_pattern=? and itemBrand=?',
        [gm, gs, gs2, cat, pettern, brand]);
  }
}
