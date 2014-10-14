function (doc) {
    if (doc) {
        emit(doc._id, {_id: doc});
    }
}
