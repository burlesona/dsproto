function (head, req) {
    provides('json', function () {
        var key, doc, parent, row,
            docs = {},
            out = [],
            startkey = req.query.startkey,
            root_id = startkey ? startkey[startkey.length - 1] : null;

        while (row = getRow()) {
            doc = row.doc
            value = row.value;

            if (doc) {
                doc.id = value.id;
                doc.parent_id = value.parent_id;
                doc.children = value.children;
                value = doc;
                delete value.child_ids;
                delete value.ancestors;
                if (!value.children || value.children.length == 0) {
                    delete value.children;
                }
            }

            docs[value.id] = value;

            if (root_id == null && value.parent_id == null || value.id == root_id) {
                out.push(value);
            }
        }

        for (key in docs) {
            doc = docs[key];

            if (doc.parent_id && docs[doc.parent_id]) {
                parent = docs[doc.parent_id];
                parent.children[parent.children.indexOf(doc.id)] = doc;
                delete doc.parent_id;
            }
        }

        for (key in docs) {
            doc = docs[key];
            if (doc.children && doc.children.length > 0) {
                doc.children = doc.children.filter(function (val) {
                    return typeof val !== 'string';
                });
            }
        }

        out = out[0] || {};
        out = out.children || [];
        return JSON.stringify(out);
    });
}
