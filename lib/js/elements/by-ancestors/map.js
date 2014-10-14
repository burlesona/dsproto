function (doc) {
    if (doc.ancestors) {
        emit(doc.ancestors.concat([doc._id]), {
            id: doc._id,
            parent_id: doc.parent_id,
            children: doc.child_ids || null
        });
    }
}
