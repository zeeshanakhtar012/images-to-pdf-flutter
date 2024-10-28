import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImagePdfScreen extends StatefulWidget {
  @override
  _ImagePdfScreenState createState() => _ImagePdfScreenState();
}

class _ImagePdfScreenState extends State<ImagePdfScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  List<String> _details = [];

  Future<void> _pickImage(ImageSource source, {int? index}) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (index != null) {
          _images[index] = image; // Replace image at the given index
        } else {
          _images.add(image); // Add new image to the list
          _details.add(''); // Add an empty detail for the new image
        }
      });
    }
  }

  Future<void> _generatePdf(String pdfName) async {
    final pdf = pdfWidgets.Document();
    for (int i = 0; i < _images.length; i++) {
      final imageFile = File(_images[i].path);
      final image = pdfWidgets.MemoryImage(imageFile.readAsBytesSync());
      pdf.addPage(pdfWidgets.Page(
        build: (pdfWidgets.Context context) {
          return pdfWidgets.Column(
            crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
            children: [
              pdfWidgets.Container(
                decoration: pdfWidgets.BoxDecoration(
                  border: pdfWidgets.Border.all(color: PdfColors.grey, width: 1),
                ),
                child: pdfWidgets.Image(image),
              ),
              pdfWidgets.SizedBox(height: 10),
              pdfWidgets.Text('Details: ${_details[i]}', style: pdfWidgets.TextStyle(fontSize: 14)),
              pdfWidgets.SizedBox(height: 20),
            ],
          );
        },
      ));
    }

    final output = await getExternalStorageDirectory();
    final folderPath = path.join(output!.path, 'MyPDFs'); // Create a new folder
    await Directory(folderPath).create(recursive: true); // Ensure the directory exists

    final filePath = path.join(folderPath, '$pdfName.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to $filePath')),
    );
  }

  Future<void> _showPdfNameDialog() async {
    String pdfName = '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter PDF Name'),
          content: TextField(
            decoration: InputDecoration(hintText: "PDF Name"),
            onChanged: (value) {
              pdfName = value; // Update PDF name
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: Text('Generate'),
              onPressed: () {
                if (pdfName.isNotEmpty) {
                  _generatePdf(pdfName); // Generate PDF with the entered name
                  Navigator.of(context).pop(); // Close dialog
                } else {
                  // Optionally, show an error if the name is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a name for the PDF.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image to PDF")),
      body: Column(
        children: [
          // Row for Image Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.camera),
                onPressed: () => _pickImage(ImageSource.camera), // Use _pickImage without index
              ),
              IconButton(
                icon: Icon(Icons.photo),
                onPressed: () => _pickImage(ImageSource.gallery), // Use _pickImage without index
              ),
            ],
          ),

          // List for Displaying Selected Images and Details
          Expanded(
            child: ListView.builder(
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        // Allow the user to change the selected image
                        final XFile? newImage = await _picker.pickImage(source: ImageSource.gallery);
                        if (newImage != null) {
                          _pickImage(ImageSource.gallery, index: index); // Replace with new image
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            Image.file(
                              File(_images[index].path),
                              fit: BoxFit.cover,
                              height: 200, // Height for image display
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: "Details",
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    _details[index] = value; // Update details
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Button to Generate PDF
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _showPdfNameDialog, // Show dialog for PDF name
              child: Text("Generate PDF"),
            ),
          ),
        ],
      ),
    );
  }
}
