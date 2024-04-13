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
    Author: ex.ColumnType.STRING
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
    author: book?.get("Author")
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
      body: "Title, author, and publishedAt are required"
    };
  }
  
  let response = {
    bookID: util.uuidv4(),
    title: title,
    author: author,
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
  db.insert(id, {Author: author, Title: title});

  let result = http.get("{api.url}/books/{id}");

  let body = Json.parse(result.body);

  expect.equal(result.status, 200);
  expect.equal(body.get("id"), id);
  expect.equal(body.get("author"), author);
  expect.equal(body.get("title"), title);
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