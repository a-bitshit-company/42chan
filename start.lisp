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
	(new-post board thread post))

      (if (or (not thread) (equal thread ""))
	(display-posts (caar (cl-mysql:query (format nil "SELECT id,board,content FROM Posts WHERE board = \"~A\" AND OPid IS NULL" board))))
	(display-posts (caar (cl-mysql:query (format nil "SELECT id,board,content FROM Posts WHERE board = \"~A\" AND OPid = ~A" board thread)))))
) ) ) )

(defun display-posts (posts)
  (loop for p in posts do
    (net.html.generator:html
      ((:div class "post")
        (:hr)
	((:a id (car p) href (format nil "view?board=~A&thread=~A" (cadr p) (car p))) (:princ-safe (car p)))
	" on "
	((:a href (format nil "view?board=~A" (cadr p) )) (:princ-safe (cadr p)))
	(:p (:princ-safe (caddr p)))
) ) ) )
	      
(defun gen-boardlist ()
  (net.html.generator:html
  ((:link :rel "stylesheet" :href "css/style.css"))
  ((:div class "boards")
    (:hr)
    (:b "|")
    (loop for b in (caar (cl-mysql:query "SELECT * FROM Boards")) do
      (net.html.generator:html
	" "
        ((:a href (format nil "view?board=~A" (car b))) (:princ-safe (car b)))
	(:b " |")
    ) )
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
     ((:input :type "submit"
              :value "post")))
) )

(defun new-post (board thread post)
  (cl-mysql:query "ALTER TABLE Posts AUTO_INCREMENT = 1;")
  (handler-case
    (cl-mysql:query 
      (if (and thread (not (equal thread "")))
	(format nil "INSERT INTO Posts VALUES(\"~A\", \"~A\", \"~A\", NULL, NULL, NULL, NULL);"
			      (cl-ppcre:regex-replace-all "\"" board "\\\"")
			      (cl-ppcre:regex-replace-all "\"" thread "\\\"")
			      (cl-ppcre:regex-replace-all "\"" post "\\\""))
	(format nil "INSERT INTO Posts VALUES(\"~A\", NULL, \"~A\", NULL, NULL, NULL, NULL);"
			      (cl-ppcre:regex-replace-all "\"" board "\\\"")
			      (cl-ppcre:regex-replace-all "\"" post "\\\""))))
    (condition (c)))
  (net.html.generator:html (:html
    (:head (:title "posted: " (:princ-safe post)))
      (:body
        (:p "posted: " (:b (:princ-safe post))
) ) ) ) )

(defun gen-index (req ent)
  (net.aserve:with-http-response (req ent)
    (net.aserve:with-http-body (req ent)
      (net.html.generator:html
	(:html
	  (:head
	    (:title
	      "test")
	    ((:link :rel "stylesheet" :href "css/style.css"))
	    (:body
	      (gen-boardlist)
	      (:p (:small "the time is "
			  (:princ-safe (get-universal-time))))
	      (:h1 "42chan")
	      (:hr)
	      (:p "Welcome to 42chan, the Textboard to answer all your Questions")
	      (:p "sauce is " ((:a href "https://github.com/a-bitshit-company/42chan") "here"))
	      (:p "below are all the posts on here:")
	      (display-posts (caar (cl-mysql:query "SELECT id,board,content FROM Posts ORDER BY id DESC" )))
) ) ) ) ) ) )
