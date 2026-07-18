module contract_tests @test;

import parser_tests;

import analyzer::parser;
import analyzer::core;
import std::io;
import std::collections::list;
import std::io::file;
import std::io::path;


//fn void contract_with_expr_checks()
//{
//	String source_code = `
//		module hello;
//
//		<*
//			Hello there
//			@param [in] a : "my param"
//			@require a > 0
//			@ensure return > 0
//		*>
//		fn int foo(int a) {}
//	`;
//	AnalyzerContext* context = context::create(tmem);
//	bool success = context::process(context, source_code, "test");
//	test::eq(success, true);
//
//	Module* mod = context.modules.get("hello")!!;
//
//	test::eq(parser_tests::count_kind(mod, MODULE_DECL), 1);
//	test::eq(parser_tests::count_kind(mod, CONTRACT_DECL), 1);
//
//	foreach (node : mod.nodes)
//	{
//		if (node.kind == CONTRACT_DECL)
//		{
//			ContractDecl* decl = node.as(ContractDecl);
//			io::printfn("%s", string::from_struct(tmem, *decl));
//			test::eq(decl.comment.text, "Hello there");
//			test::eq(decl.deprecated, null);
//			test::eq(decl.ensures.len, 1);
//			test::eq(decl.requires.len, 1);
//			test::eq(decl.params.len, 1);
//
//			{
//				Node* req_expr     = decl.requires[0];
//				ContractExpr* expr = req_expr.as(ContractExpr);
//				ExprList* list     = expr.exprs.as(ExprList);
//				BinaryExpr* bin    = list.exprs[0].as(BinaryExpr);
//				test::eq(bin.left.as(IdentExpr).ident.text, "a");
//				test::eq(bin.op, OperatorKind.OP_GT);
//				test::eq(bin.right.as(LiteralExpr).integer, 0u);
//			}
//
//			{
//				Node* req_expr     = decl.ensures[0];
//				ContractExpr* expr = req_expr.as(ContractExpr);
//				ExprList* list     = expr.exprs.as(ExprList);
//				BinaryExpr* bin    = list.exprs[0].as(BinaryExpr);
//				test::eq(bin.left.as(IdentExpr).ident.text, "return");
//				test::eq(bin.op, OperatorKind.OP_GT);
//				test::eq(bin.right.as(LiteralExpr).integer, 0u);
//			}
//
//			{
//				Node* param         = decl.params[0];
//				ContractParam* expr = param.as(ContractParam);
//				test::eq(expr.ident.text, "a");
//				test::eq(expr.modifier, InOutModifier.IN);
//				test::eq(expr.description.text, "\"my param\"");
//			}
//		}
//	}
//}

fn void module_duplicate_contract_error()
{
	String source_code = `
		<* first doc *>
		<* second doc *>
		module hello;

		fn void foo() {}
	`;
	AnalyzerContext* context = context::create(tmem);
	bool success = context::process(context, source_code, "test");
	test::eq(success, true);

	Module* mod = context.modules.get("hello")!!;

	test::eq(mod.module_decls[0].contract.get()!!.flags.has_error, true);
	foreach (node : context.current_source_file.ast.nodes) {
		io::printn(node.kind);
	}
}

fn void function_duplicate_contract_error()
{
	String source_code = `
		module hello;

		<* first doc *>
		<* second doc *>
		fn void foo() {}
	`;
	AnalyzerContext* context = context::create(tmem);
	bool success = context::process(context, source_code, "test");
	test::eq(success, true);

	Module* mod = context.modules.get("hello")!!;
	foreach(node : mod.nodes)
	{
		io::printn(node.kind);
	}
	FnDecl* fn_decl = mod.nodes[1].as(FnDecl);
	test::eq(fn_decl.contract.get!!.
}
/*
fn void contract_description()
{
	String source_code = `
		module hello;

		<* 
		 this is a comment
		*>
		fn void foo() {}
	`;
	Workspace ws;
	ws.init(mem, { .use_sema = true });
	defer ws.free();
	ProcessResult res = workspace::process(&ws, mem, { .uri = "test", .source_text = source_code})!!;
	defer res.free();
	test::eq(res.has_errors, false);

	Module* mod = ws.modules.get("hello")!!;
	test::ne(mod, null);

	ModuleSection* s = mod.sections[0];
	StringPool* pool = &s.source_file.ast.string_pool;

	ContractDecl* decl = s.nodes[1].as(CONTRACT_DECL);
	io::printfn("%s", string::from_struct(tmem, *decl));
	test::eq(decl.get_comment(pool)!!.trim(), "this is a comment");
	test::eq(decl.comment.range.start, 22);
	test::eq(decl.comment.range.end, 47);
}

fn void contract_with_deprecated()
{
	String source_code = `
		module hello; 

		<*
			Hello there
			@param [in] a : "my param"
			@require a > 0
			@ensure return > 0
			@deprecated "This is deprecated!"
			@pure
		*>
		fn int foo(int a) {}
	`;
	Workspace ws;
	ws.init(mem, { .use_sema = true });
	defer ws.free();
	ProcessResult res = workspace::process(&ws, mem, { .uri = "test", .source_text = source_code})!!;
	defer res.free();
	test::eq(res.has_errors, false);
	test::eq(ws.modules.len(), 1);

	Module* mod = ws.modules.get("hello")!!;
	test::ne(mod, null);
	io::printfn("%s", mod.name);
	test::eq(mod.name, "hello");
	test::eq(mod.sections.len(), 1);

	ModuleSection* s = mod.sections[0];
	StringPool* pool = &s.source_file.ast.string_pool;

	test::eq(parser_tests::count_kind(s, MODULE_DECL), 1);
	test::eq(parser_tests::count_kind(s, CONTRACT_DECL), 1);

	foreach (node : s.nodes)
	{
		if (node.kind == CONTRACT_DECL)
		{
			ContractDecl* decl = node.as(CONTRACT_DECL);
			io::printfn("%s", string::from_struct(tmem, *decl));
			test::eq(decl.get_comment(pool)!!.trim(), "Hello there");
			test::eq(decl.ensures.len, 1);
			test::eq(decl.requires.len, 1);
			test::eq(decl.params.len, 1);
			test::eq(decl.is_pure, true);

			AttributeDecl* attr = decl.deprecated.as(ATTRIBUTE_DECL);
			test::eq(attr.kind, AttributeKind.DEPRECATED);
			LiteralExpr* lit = attr.exprs[0].as(LITERAL_EXPR);
			test::eq(pool.get(lit.string)!!, "This is deprecated!");



			{
				Node* req_expr     = decl.requires[0];
				ContractExpr* expr = req_expr.as(CONTRACT_EXPR);
				ExprList* list     = expr.exprs.as(EXPR_LIST);
				BinaryExpr* bin    = list.exprs[0].as(BINARY_EXPR);
				test::eq(bin.left.as(IDENT_EXPR).get_ident(pool)!!, "a");
				test::eq(bin.op, OperatorKind.OP_GT);
				test::eq(bin.right.as(LITERAL_EXPR).integer, 0u);
			}



			{
				Node* req_expr     = decl.ensures[0];
				ContractExpr* expr = req_expr.as(CONTRACT_EXPR);
				ExprList* list     = expr.exprs.as(EXPR_LIST);
				BinaryExpr* bin    = list.exprs[0].as(BINARY_EXPR);
				test::eq(bin.left.as(IDENT_EXPR).get_ident(pool)!!, "return");
				test::eq(bin.op, OperatorKind.OP_GT);
				test::eq(bin.right.as(LITERAL_EXPR).integer, 0u);
			}



			{
				Node* param         = decl.params[0];
				ContractParam* expr = param.as(CONTRACT_PARAM);
				test::eq(pool.get(expr.ident.id)!!, "a");
				test::eq(expr.modifier, InOutModifier.IN);
				test::eq(expr.get_description(pool)!!, "\"my param\"");
			}
		}
	}
}
