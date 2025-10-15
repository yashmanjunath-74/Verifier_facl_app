class Peer {
  final String id;
  Peer(this.id);

  @override
  String toString() => 'Peer(id: $id)';
}

class P2PMessage {
  final String data;
  final Peer sender;
  P2PMessage({required this.data, required this.sender});
}
