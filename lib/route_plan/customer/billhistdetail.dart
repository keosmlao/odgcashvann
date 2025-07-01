import 'package:flutter/material.dart';

class BillHistDetail extends StatefulWidget {
  String? doc_no;
  BillHistDetail({super.key, this.doc_no});

  @override
  State<BillHistDetail> createState() => _BillHistDetailState();
}

class _BillHistDetailState extends State<BillHistDetail> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      displacement: 250,
      backgroundColor: Colors.yellow,
      color: Colors.red,
      strokeWidth: 3,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1000));
        // setState(() {
        //   itemCount = itemCount + 1;
        // });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "ລາຍການໃນບິນ",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              }),
        ),
        body: SingleChildScrollView(
          child: Container(
              // child: FutureBuilder<List<BillDetailModel>>(
              //   initialData: const <BillDetailModel>[],
              //   future: fetchBillDetail(widget.doc_no.toString()),
              //   builder: (context, snapshot) {
              //     if (snapshot.hasError ||
              //         snapshot.data == null ||
              //         snapshot.connectionState == ConnectionState.waiting) {
              //       return const Text("ບໍພົບລາຍການ");
              //       // const CircularProgressIndicator();
              //     } else {
              //       return Container(
              //           width: double.infinity,
              //           decoration: BoxDecoration(
              //             border: Border.all(
              //               width: 1,
              //             ),
              //             borderRadius:
              //                 const BorderRadius.all(Radius.circular(1)),
              //           ),
              //           margin: const EdgeInsets.all(1.0),
              //           child: DataTable(
              //             columns: const [
              //               DataColumn(label: Text('ລາຍການ')),
              //               DataColumn(label: Text('ຫົວໜ່ວຍ')),
              //             ],
              //             rows: List.generate(
              //               snapshot.data!.length,
              //               (index) {
              //                 var emp = snapshot.data![index];
              //                 return DataRow(cells: [
              //                   DataCell(
              //                     Text(emp.itemName.toString()),
              //                   ),
              //                   DataCell(
              //                     Text('${emp.qty}-${emp.unitCode}'),
              //                   ),
              //                 ]);
              //               },
              //             ).toList(),
              //           ));
              //     }
              //   },
              // ),
              ),
        ),
      ),
    );
  }
}
