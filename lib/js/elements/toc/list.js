function (head, req) {
    provides('json', function () {
        var key, doc, parent, row, docs = {}, out = [];

        while (row = getRow()) {
            doc = row.doc;
            value = row.value;

            if (doc) {
                value = {
                    id: value.id,
                    domain: doc.domain || 'BodyMatter',
                    type: doc.type || 'Section',
                    depth: doc.depth,
                    previewable: doc.previewable,
                    title: doc.title,
                    parent_id: value.parent_id,
                    children: value.children
                };
            }


            docs[value.id] = value;
            if (value.parent_id == null) {
                out.push(value);
            }
        }

        for (key in docs) {
            doc = docs[key];

            if (doc.parent_id) {
                parent = docs[doc.parent_id];
                parent.children[parent.children.indexOf(doc.id)] = doc;
                delete doc.parent_id;
            }
        }

        for (key in docs) {
            doc = docs[key];
            doc.children = doc.children.filter(function (val) {
                return typeof val !== 'string';
            });
        }

        if (out.length === 1) {
            out = out[0];
        }

        return JSON.stringify(out);
    });
}
