import 'package:yourimageshare/yourimageshare.dart';

Future<void> main() async {
  final client = YourImageShareClient('YOUR_API_KEY');

  try {
    final result = await client.upload('photo.jpg');
    print(result.direct); // https://yourimageshare.com/ib/aB3xY9qRz1
  } on YourImageShareException catch (e) {
    print('${e.status}: ${e.message}');
  }
}
