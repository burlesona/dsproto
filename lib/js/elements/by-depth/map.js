function (doc) {
    if (doc.document_id) {
        emit([doc.document_id, doc.depth], {
            id: doc._id,
            parent_id: doc.parent_id,
            children: doc.child_ids || null
        });
    }
}
