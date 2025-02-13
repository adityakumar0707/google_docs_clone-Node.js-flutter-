import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs/models/document_model.dart';
import 'package:google_docs/repository/auth_repository.dart';
import 'package:google_docs/repository/document_repository.dart';
import 'package:google_docs/repository/socket_repository.dart';
import 'package:google_docs/widgets/loader.dart';
import 'package:routemaster/routemaster.dart';
import '../colors.dart';
import '../models/error_model.dart';
import 'package:quill_delta/quill_delta.dart' as Delta;




class DocumentScreen extends ConsumerStatefulWidget {
  final String id;
  const DocumentScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  TextEditingController titleController = TextEditingController(text: 'Untitled Document');
  quill.QuillController? _controller ;
  ErrorModel? errorModel;
  SocketRepository socketRepository = SocketRepository();


  @override
  void initState() {
    super.initState();
    print('hello');
    socketRepository.joinRoom(widget.id);
    fetchDocumentData();

    socketRepository.changeListner((p0) => null);
  }

  void fetchDocumentData() async{
    errorModel = await ref.read(documentRepositoryProvider).getDocumentById(ref.read(userProvider)!.token, widget.id);
    //print("hii"+ errorModel!.data);
    if(errorModel!.data !=null){
      titleController.text= (errorModel!.data as DocumentModel).title;
      _controller = quill.QuillController(
          document: errorModel!.data.content.isEmpty ? quill.Document() :
          quill.Document.fromDelta(Delta.fromJSON(
              errorModel!.data.content)) ,
          selection: selection);
      setState(() {});
    }
  }


  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
  }

void updateTitle(WidgetRef ref, String title){
    ref.read(documentRepositoryProvider).
    updateTitle(token: ref.read(userProvider)!.token,
        id: widget.id,
        title: title
    );
}

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Loader());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'http://localhost:3000/#/document/${widget.id}')).then(
                      (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Link copied!',
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.lock,
                size: 16,
              ),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlueColor,
              ),
            ),
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Routemaster.of(context).replace('/');
                },
                child: Image.asset(
                  'assets/images/docs-logo.png',
                  height: 40,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: kBlueColor,
                      ),
                    ),
                    contentPadding: EdgeInsets.only(left: 10),
                  ),
                  onSubmitted: (value) {
                    updateTitle(ref, value);
                  },
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: kGreyColor,
                width: 0.1,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            quill.QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _controller!,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('de'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SizedBox(
                width: 750,
                child: Card(
                  color: kWhiteColor,
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        controller: _controller!,
                        readOnly: false,
                        sharedConfigurations: const QuillSharedConfigurations(
                          locale: Locale('de'),
                        ),
                      ),
                    ),
                ),
              ),
              )
            )
          ],
        ),
      ),
    );
  }
}