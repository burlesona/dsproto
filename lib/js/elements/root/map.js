function (doc) {
    if (doc.type === 'Book') {
        emit(doc._id, {_id: doc._id});
    }
}
