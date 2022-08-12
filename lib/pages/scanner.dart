import 'dart:io';

import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class BarcodeScanner extends StatefulWidget {
  final int? id;
  final String? name;
  const BarcodeScanner({super.key, this.id, this.name});

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  List stock = [];
  int picking_type_id = 1;
  int warehouse_id = 1;
  int partner_id = 1;

//final orpc = OdooClient('https://home.seacorp.vn/');
  final orpc = OdooClient('https://pilot.seateklab.vn/');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getStockPicking();
    });
  }

  getStockPicking() async {
    HttpOverrides.global = MyHttpOverrides();
    //await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    final stock2 = await orpc.callKw({
      'model': 'stock.picking',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['name', '=', widget.name],
        ],
        'fields': ['id', 'picking_type_id'],
      },
    });
    setState(() {
      stock = stock2;
    });
    for (var element in stock) {
      setState(() {
        picking_type_id = element['picking_type_id'][0];
      });
    }
    //await getPickingType();
  }
  /*getPickingType() async {
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    final type = await orpc.callKw({
      'model': 'stock.picking.type',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['id', '=', picking_type_id],
        ],
        'fields': ['warehouse_id'],
      },
    });
    for (var element in type) {
      setState(() {
        warehouse_id = element['warehouse_id'][0];
      });
    }
    await getWarehouse();
  }
  getWarehouse() async{
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    final warehouse = await orpc.callKw({
      'model': 'stock.warehouse',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['id', '=', warehouse_id],
        ],
        'fields': ['partner_id'],
      },
    });
    for (var element in warehouse) {
      setState(() {
        partner_id = element['partner_id'][0];
      });
    }
    await getPartner();
  }
  getPartner() async{
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    final partner = await orpc.callKw({
      'model': 'res.partner',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['id', '=', partner_id],
        ],
        'fields': ['id','name','phone'],
      },
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Barcode scan')),
        body: Text(widget.name.toString()));
  }
}
