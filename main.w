bring cloud;
bring ex;
bring expect;
bring http;
bring util;

let api = new cloud.Api() as "books-manager";

let db = new ex.Table({
  name: "books",
  primaryKey: "ID",
  columns: {
    Title: ex.ColumnType.STRING,
    Author: ex.ColumnType.STRING,
    CreatedAt: ex.ColumnType.DATE
  }
});

api.get("/books/:bookID", inflight (req: cloud.ApiRequest) => {
  let bookID = req.vars.get("bookID");
  log("Getting record with ID {bookID}");
  
  let book = db.tryGet(bookID);

  if (book == nil) {
    return cloud.ApiResponse {
     status: 404,
     body: "Book not found"
    };
  }

  let response = {
    id: book?.get("ID"),
    title: book?.get("Title"),
    author: book?.get("Author"),
    createdAt: book?.get("CreatedAt")
  };

  return cloud.ApiResponse {
   status: 200,
   body: Json.stringify(response)
  };
});

api.post("/books", inflight (req: cloud.ApiRequest) => {
  let bookRequest = Json.tryParse(req.body);

  if (bookRequest == nil) {
    return cloud.ApiResponse {
      status: 400,
      body: "Request invalid"
    };
  }

  let title = bookRequest?.tryGet("title")?.tryAsStr();
  let author = bookRequest?.tryGet("author")?.tryAsStr();

  if (title == nil || author == nil) {
    return cloud.ApiResponse {
      status: 400,
      body: "Title and author are required"
    };
  }

  let bookID = util.uuidv4();
  let createdAt = std.Datetime.utcNow();
  let var month = "{createdAt.month + 1}";

  if (createdAt.month < 10) {
    month = "0{month}";
  }

  db.insert(bookID, {
    Title: title, 
    Author: author, 
    CreatedAt: "{createdAt.year}-{month}-{createdAt.dayOfMonth}"
  });
  
  let response = {
    bookID: bookID,
    title: title,
    author: author,
    createdAt: createdAt.toIso()
  };

  return cloud.ApiResponse {
   status: 200,
   body: Json.stringify(response)
  };
});

/*
***********
Tests
***********
*/
test "GET /books/:bookID should return 200 when record exists" {
  let id = "1";
  let author = "An Author";
  let title = "A Book";
  let createdAt = "2024-04-14";
  db.insert(id, {Author: author, Title: title, CreatedAt: createdAt});

  let result = http.get("{api.url}/books/{id}");

  let body = Json.parse(result.body);

  expect.equal(result.status, 200);
  expect.equal(body.get("id"), id);
  expect.equal(body.get("author"), author);
  expect.equal(body.get("title"), title);
  expect.equal(body.get("createdAt"), createdAt);
}

test "GET /books/:bookID should return 404 when record is not found" {
  let id = "1";
  let result = http.get("{api.url}/books/{id}");

  expect.equal(result.status, 404);
}

test "POST /books should return 200 with correct body " {
  let body = Json.stringify({title: "A Title", author: "An Author"});

  let result = http.post("{api.url}/books", { body: body });

  expect.equal(result.status, 200);
}

test "POST /books should return 400 without body " {

  let result = http.post("{api.url}/books");

  expect.equal(result.status, 400);
}

test "POST /books should return 400 with empty body " {
  let body = Json.stringify({});

  let result = http.post("{api.url}/books", { body: body });

  expect.equal(result.status, 400);
}

test "POST /books should return 400 without title " {
  let body = Json.stringify({ author: "An Author"});

  let result = http.post("{api.url}/books", { body: body });

  expect.equal(result.status, 400);
}

test "POST /books should return 400 without author " {
  let body = Json.stringify({title: "A Title" });

  let result = http.post("{api.url}/books", { body: body });

  expect.equal(result.status, 400);
}