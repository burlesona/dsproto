function (doc) {
    if (doc.type && doc.type == 'Book') {
        emit(doc._id, null);
    }
}
