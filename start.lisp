(load "~/quicklisp/setup.lisp")
(ql:quickload :aserve)
(ql:quickload :cl-mysql)
(ql:quickload :cl-ppcre)
(ql:quickload :cl-json)

(net.aserve:start)
(cl-mysql:connect)
(cl-mysql:query "USE chan")
(net.aserve:publish-file :path "/favicon.ico" :file "/root/favicon.ico")
(net.aserve:publish-directory :prefix "/css" :destination "/root/42chan/css")

(net.aserve:publish :path "/"
		    :content-type "text/html"
		    :function 'gen-index)

(net.aserve:publish :path "/favicon.ico"
		    :content-type "text/html"
		    :function 'favicon)

(net.aserve:publish :path "/api"
		    :content-type "text/json"
		    :function 'gen-json)

(net.aserve:publish :path "/post"
		    :content-type "text/html"
		    :function 'gen-board)

(net.aserve:publish :path "/view"
		    :content-type "text/html"
		    :function 'gen-board)

(defun gen-board (req ent)
  (let ((post (net.aserve:request-query-value "post" req)) 
        (board (net.aserve:request-query-value "board" req))
	(thread (net.aserve:request-query-value "thread" req))
	(name (net.aserve:request-query-value "name" req))
        (board-info
	  (caaar (cl-mysql:query (format nil "SELECT * FROM Boards WHERE short=\"~A\""
					 (net.aserve:request-query-value "board" req))))))

  (net.aserve:with-http-response (req ent)
    (net.aserve:with-http-body (req ent)

      (gen-boardlist)
      (net.html.generator:html
	((:div class "board-info")
	 (:b (:princ-safe (car board-info) " - " (cadr board-info)))
	 (:br)
	 (:princ-safe (caddr board-info))))

      (display-post-form board thread)
      (if (and post (not (equal post "")))
	(new-post board thread post name))

      (if (or (not thread) (equal thread ""))
	(display-posts (caar (cl-mysql:query (format nil "SELECT id,OPid,nickname,board,content FROM Posts WHERE board = \"~A\" AND OPid IS NULL ORDER BY id DESC" board))))
	(display-posts (caar (cl-mysql:query (format nil "SELECT id,OPid,nickname,board,content FROM Posts WHERE OPid = ~A ORDER BY id DESC" thread)))))
) ) ) )

(defun display-posts (posts)
  (loop for p in posts do
    (net.html.generator:html
      ((:div class "post")
        (:hr)
	((:a id (car p) href (format nil "view?board=~A&thread=~A" (cadddr p) (car p))) (:princ-safe (car p)))
      	(if (and (caddr p) (not (equal (caddr p) "")))
    	  (net.html.generator:html
	  " ("
	  ((:a href (format nil "view?board=~A&thread=~A" (cadddr p) (car p))) (:princ-safe (caddr p)))
	  ") "))
      	(if (and (cadr p) (not (equal (cadr p) "")))
    	  (net.html.generator:html
	  " to "
	  ((:a id (cadr p) href (format nil "view?board=~A&thread=~A" (cadddr p) (cadr p))) (:princ-safe (cadr p)))))
	" on "
	((:a href (format nil "view?board=~A" (cadddr p) )) (:princ-safe (cadddr p)))
	(:pre (:princ (car (cddddr p))))
) ) ) )
	      
(defun gen-boardlist ()
  (net.html.generator:html
  ((:link :rel "stylesheet" :href "css/style.css"))
  ((:div class "boards")
    (:hr)
    (loop for b in (caar (cl-mysql:query "SELECT * FROM Boards")) do
      (net.html.generator:html
        ((:a href (format nil "view?board=~A" (car b))) (:princ-safe (car b)))
	(:b " | ")
    ) )
    ((:a href "/") "home")
    (:hr)
) ) )

(defun display-post-form (board thread)
  (net.html.generator:html
    ((:form :action 
	    (if (and thread (not (equal thread "")))
	      (format nil "view?board=~A&thread=~A" board thread)
	      (format nil "view?board=~A" board))
	    :method "post")
     ((:textarea
              :name "post"
              :placeholder "shitpost (2048 characters max)"
              :rows 10
              :cols 45
              :maxlength 2048))
     (:br)
     ((:input :type "text"
	      :name "name"
	      :placeholder "name"))
     ((:input :type "submit"
              :value "post")))
) )

(defun new-post (board thread post name)
  (cl-mysql:query "ALTER TABLE Posts AUTO_INCREMENT = 1;")
  (handler-case
    (cl-mysql:query 
	(format nil "INSERT INTO Posts VALUES(\"~A\", ~A, \"~A\", ~A, NULL);"
			      (cl-ppcre:regex-replace-all "\"" board "\\\"")
      			      (if (and thread (not (equal thread "")))
			        (cl-ppcre:regex-replace-all "\"" thread "\\\"")
				"NULL")
			      (cl-ppcre:regex-replace-all "\"" post "\\\"")
      			      (if (and name (not (equal name "")))
				(format nil "\"~A\""
			        (cl-ppcre:regex-replace-all "\"" name "\\\""))
				"NULL")))
    (condition (c)))
  (net.html.generator:html (:html
    (:head (:title "posted: " (:princ-safe post)))
      (:body
        (:p "posted: " (:b (:princ post))
) ) ) ) )

(defun gen-index (req ent)
  (net.aserve:with-http-response (req ent)
    (net.aserve:with-http-body (req ent)
      (net.html.generator:html
	(:html
	  (:head
	    (:title
	      "42chan")
	    ((:link :rel "stylesheet" :href "css/style.css"))
	    ((:meta :charset "UTF-8")))
	  (:body
	    (gen-boardlist)
	    (:p (:small "the time is "
	      (:princ-safe (get-universal-time))))
	    (:h1 "42chan")
	    (:hr)
	    (:p "Welcome to 42chan, the textboard to answer all of your questions")
	    (:p "sauce is " ((:a href "https://github.com/a-bitshit-company/42chan") "here"))
	    (:p "below are all posts:")
	    (display-posts (caar (cl-mysql:query "SELECT id,OPid,nickname,board,content FROM Posts ORDER BY id DESC" )))
) ) ) ) ) )

(defun favicon (req ent)
  (net.aserve:with-http-response (req ent)
    (net.aserve:with-http-body (req ent)
      (net.html.generator:html
	((:link :rel "icon" :href "data:image/x-icon;base64,AAABAAEAEBAQAAAAAAAoAQAAFgAAACgAAAAQAAAAIAAAAAEABAAAAAAAgAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAsC8qAP+EAACzh1cAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAACAAAAAAAAACAAAAAAAAEiAAAAADAAAiAAAAAAMzAiAAAAAAAAMzAAAAAAAAAiMzMAAAAAAAADAzAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA" :type "image/x-icon"))
) ) ) ) 
