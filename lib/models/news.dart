class News {
  News(this.title, this.body);

  final String title;
  final String body;

  bool ifNewsContainParameters(List<String> parameters) {
    for(final param in parameters) {
      if(title.contains(param)){
        return true;
      }
      if(body.contains(param)){
        return true;
      }
    }
    return false;
  }
}