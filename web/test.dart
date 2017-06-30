import 'dart:isolate';

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
}

void echo(Tuple2<SendPort, String> data) {
  final triggerPort = new ReceivePort();
  triggerPort.listen((d) => data.item1.send(d));
  data.item1.send(triggerPort.sendPort);
  data.item1.send(data.item2);
}

void main() {
  final port = new ReceivePort();
  SendPort triggerPort;
  var i = 10;
  port.listen((d) {
    if (d is SendPort) {
      triggerPort = d;
      triggerPort.send('Hello? Is there anybody there?');
    } else {
      print(d);
      if (--i > 0) {
        triggerPort.send('$d echo');
      }
    }
  });

  Isolate.spawn(echo, new Tuple2<SendPort, String>(port.sendPort, '...'));
}
