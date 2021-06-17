(load "~/quicklisp/setup.lisp")
(ql:quickload :aserve)
(ql:quickload :cl-mysql)
(ql:quickload :cl-ppcre)

(net.aserve:start)
(cl-mysql:connect)
(cl-mysql:query "USE chan")

(net.aserve:publish :path "/"
		    :content-type "text/html"
		    :function 'gen-helloworld)

(net.aserve:publish :path "/post"
		    :content-type "text/html"
		    :function 'gen-helloworld)

(net.aserve:publish :path "/boards/g"
		    :content-type "text/html"
		    :function 'gen-gview)

(defun gen-boardlist ()
  (net.html.generator:html
  ((:div class "boards")
    (loop for b in (caar (cl-mysql:query "SELECT * FROM Boards")) do
      (net.html.generator:html
        ((:a href (car b)) (:princ-safe (car b)))
) ) ) ) )
	      
(defun gen-gview (req ent)
  (net.aserve:with-http-response (req ent)
    (net.aserve:with-http-body (req ent)
      (loop for p in (caar (cl-mysql:query "SELECT id,content FROM Posts WHERE board = \"g\" AND OPid IS NULL")) do
        (net.html.generator:html
	  ((:div class "post")
	   (:hr)
	   ((:a id (car p)) (:princ-safe (car p)))
	   (:br)
	   (:princ-safe (format nil "~{~A~}" (cdr p)))
) ) ) ) ) )

(defun display-post-form()
  (net.html.generator:html
    ((:form :action "post" :method "post")
     ((:textarea
              :name "post"
              :placeholder "shitpost (2048 characters max)"
              :rows 10
              :cols 45
              :maxlength 2048))
     (:br)
     ((:input :type "text"
              :name "pswd"
              :placeholder "password for deleting this post later"))
     ((:input :type "submit"
              :value "post")))
) )

(defun new-post (post pswd)
  (cl-mysql:query "ALTER TABLE Posts AUTO_INCREMENT = 1;")
  (handler-case
    (if (equal pswd "")
      (cl-mysql:query (format nil "INSERT INTO Posts VALUES(\"g\", NULL, \"~A\", NULL, NULL, NULL, NULL);" (cl-ppcre:regex-replace-all "\"" post "\\\"")))
      (cl-mysql:query (format nil "INSERT INTO Posts VALUES(null, \"~A\", \"~A\");" (cl-ppcre:regex-replace-all "\"" post "\\\"")
                                                                                        (cl-ppcre:regex-replace-all "\"" pswd "\\\""))))
    (condition (c)))
  (net.html.generator:html (:html
    (:head (:title "posted: " (:princ-safe pswd)))
      (:body
        (:p "posted: " (:b (:princ-safe post))
) ) ) ) )

(defun gen-helloworld (req ent)
  (let ((post (net.aserve:request-query-value "post" req))
	(pswd (net.aserve:request-query-value "pswd" req)))
  (net.aserve:with-http-response (req ent)
    (net.aserve:with-http-body (req ent)
      (net.html.generator:html
	(:html
	  (:head
	    (:title
	      "test")
	    (:body
	      (gen-boardlist)
	      (:p (:small "the time is "
			  (:princ-safe (get-universal-time))))
	      (:h1 "hello world")
	      (display-post-form)
	      (if (and post (not (equal post "")))
		(new-post post pswd))
) ) ) ) ) ) ) )

